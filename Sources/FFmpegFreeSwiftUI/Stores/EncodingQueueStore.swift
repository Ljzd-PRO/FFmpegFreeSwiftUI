import Foundation

@MainActor
public final class EncodingQueueStore: ObservableObject {
    @Published public var tasks: [EncodingTask] = []
    @Published public var selectedTaskID: EncodingTask.ID?
    @Published public var queueLog: String = ""

    private let settingsStore: SettingsStore
    private let builder = FFmpegCommandBuilder()
    private let parser = FFmpegProgressParser()
    private let sleepPreventer = SleepPreventer()
    private let runnerFactory: (FFmpegLocator, AppSettings) -> any FFmpegProcessLaunching
    private var runningProcesses: [UUID: any FFmpegProcessHandle] = [:]
    private var lastOutputUpdate: [UUID: Date] = [:]
    private var handledTerminations: Set<UUID> = []

    public init(
        settingsStore: SettingsStore,
        runnerFactory: @escaping (FFmpegLocator, AppSettings) -> any FFmpegProcessLaunching = { locator, settings in
            FFmpegRunner(locator: locator, settings: settings)
        }
    ) {
        self.settingsStore = settingsStore
        self.runnerFactory = runnerFactory
    }

    public var selectedTask: EncodingTask? {
        guard let selectedTaskID else { return tasks.first }
        return tasks.first { $0.id == selectedTaskID }
    }

    public func addFiles(_ paths: [String], preset: PresetData, customOutputDirectory: String = "") {
        for path in paths {
            let output = OutputPathBuilder.build(inputFile: path, preset: preset, customDirectory: customOutputDirectory)
            let name = URL(fileURLWithPath: path).lastPathComponent
            let task = EncodingTask(preset: preset, inputFile: path, outputFile: output, displayName: name)
            tasks.append(task)
            if selectedTaskID == nil {
                selectedTaskID = task.id
            }
        }
        if settingsStore.settings.autoStartTasks {
            startPending()
        }
    }

    public func addCommandTask(arguments: String, displayName: String, outputPath: String = "", inputPath: String = "") {
        let task = EncodingTask(
            preset: nil,
            inputFile: inputPath,
            outputFile: outputPath,
            displayName: displayName,
            commandLine: arguments
        )
        tasks.append(task)
        selectedTaskID = task.id
        if settingsStore.settings.autoStartTasks {
            startPending()
        }
    }

    public func addPresetFileTask(presetPath: String, displayName: String, outputPath: String = "", inputPath: String = "") {
        do {
            var preset = try PresetIOService.load(from: URL(fileURLWithPath: presetPath))
            if !outputPath.isEmpty {
                preset.outputLocation = outputPath
            }
            let output = outputPath.isEmpty && !inputPath.isEmpty ? OutputPathBuilder.build(inputFile: inputPath, preset: preset) : outputPath
            let task = EncodingTask(preset: preset, inputFile: inputPath, outputFile: output, displayName: displayName)
            tasks.append(task)
            selectedTaskID = task.id
            if settingsStore.settings.autoStartTasks {
                startPending()
            }
        } catch {
            queueLog = "添加预设任务失败: \(error.localizedDescription)"
        }
    }

    public func startPending() {
        let running = tasks.filter { $0.status == .running }.count
        let slots = max(settingsStore.settings.maxConcurrentTasks - running, 0)
        guard slots > 0 else { return }
        let candidates = tasks.filter { $0.status == .pending }.prefix(slots)
        for task in candidates {
            start(task)
        }
    }

    public func startSelected() {
        guard let selectedTask else { return }
        start(selectedTask)
    }

    public func start(_ task: EncodingTask) {
        guard task.status == .pending || task.status == .stopped || task.status == .failed else { return }
        if let preset = task.preset {
            if task.outputFile.isEmpty {
                task.outputFile = OutputPathBuilder.build(inputFile: task.inputFile, preset: preset)
            }
            task.commandLine = builder.build(preset: preset, input: task.inputFile, output: task.outputFile)
        }
        guard !task.commandLine.isEmpty else {
            task.status = .failed
            task.errors.append("[FFmpegFreeSwiftUI] 没有可执行命令行")
            return
        }
        let locator = FFmpegLocator(settings: settingsStore.settings)
        let runner = runnerFactory(locator, settingsStore.settings)
        task.status = .running
        task.startedAt = Date()
        task.completedAt = nil
        task.wasManuallyStopped = false
        task.progress = EncodingProgress()
        task.errors.removeAll()
        task.nonProgressOutput.removeAll()
        handledTerminations.remove(task.id)
        sleepPreventer.start()

        do {
            let running = try runner.run(argumentsLine: task.commandLine) { [weak self, weak task] line in
                Task { @MainActor in
                    self?.handleOutput(line, task: task)
                }
            } terminationHandler: { [weak self, weak task] status in
                Task { @MainActor in
                    self?.handleTermination(status, task: task)
                }
            }
            if !handledTerminations.contains(task.id) {
                runningProcesses[task.id] = running
                task.processIdentifier = running.processIdentifier
            }
            Task { [weak self, weak task, running] in
                let status = await running.waitUntilExitStatus()
                await MainActor.run {
                    self?.handleTermination(status, task: task)
                }
            }
        } catch {
            task.status = .failed
            task.errors.append("[FFmpegFreeSwiftUI] \(error.localizedDescription)")
            runningProcesses[task.id] = nil
            task.completedAt = Date()
            maybeStopSleepPreventer()
        }
    }

    public func pauseSelected() {
        guard let selectedTask else { return }
        pause(selectedTask)
    }

    public func pause(_ task: EncodingTask) {
        guard task.status == .running, let process = runningProcesses[task.id] else { return }
        process.pause()
        task.status = .paused
    }

    public func resumeSelected() {
        guard let selectedTask else { return }
        resume(selectedTask)
    }

    public func resume(_ task: EncodingTask) {
        guard task.status == .paused, let process = runningProcesses[task.id] else { return }
        process.resume()
        task.status = .running
    }

    public func stopSelected() {
        guard let selectedTask else { return }
        stop(selectedTask)
    }

    public func stop(_ task: EncodingTask) {
        task.wasManuallyStopped = true
        runningProcesses[task.id]?.stop()
        task.status = .stopped
    }

    public func removeSelected() {
        guard let selectedTask else { return }
        remove(selectedTask)
    }

    public func remove(_ task: EncodingTask) {
        if task.status == .running || task.status == .paused {
            stop(task)
        }
        runningProcesses[task.id] = nil
        handledTerminations.remove(task.id)
        tasks.removeAll { $0.id == task.id }
        selectedTaskID = tasks.first?.id
        maybeStopSleepPreventer()
    }

    public func resetSelected() {
        guard let selectedTask else { return }
        reset(selectedTask)
    }

    public func reset(_ task: EncodingTask) {
        guard task.status != .running else { return }
        task.status = .pending
        task.progress = EncodingProgress()
        task.errors.removeAll()
        task.nonProgressOutput.removeAll()
        task.realtimeOutput = ""
        task.completedAt = nil
        task.startedAt = nil
        task.wasManuallyStopped = false
        handledTerminations.remove(task.id)
    }

    public func copySelectedCommandLine() {
        guard let selectedTask else { return }
        let command = selectedTask.commandLine.isEmpty ? generatedCommand(for: selectedTask) : selectedTask.commandLine
        MacSystemServices.copyToPasteboard("ffmpeg " + command)
    }

    public func revealSelectedOutput() {
        guard let selectedTask else { return }
        let path = selectedTask.outputFile.isEmpty ? selectedTask.inputFile : selectedTask.outputFile
        guard !path.isEmpty else { return }
        MacSystemServices.revealInFinder(path: path)
    }

    public func sendMessageToSelected(_ message: String) {
        guard let selectedTask, let process = runningProcesses[selectedTask.id] else { return }
        process.send(message)
    }

    public func overwriteSelectedTaskPreset(with preset: PresetData) {
        guard let selectedTask else { return }
        selectedTask.preset = preset
        if !selectedTask.inputFile.isEmpty {
            selectedTask.outputFile = OutputPathBuilder.build(inputFile: selectedTask.inputFile, preset: preset)
            selectedTask.commandLine = builder.build(preset: preset, input: selectedTask.inputFile, output: selectedTask.outputFile)
        }
    }

    private func generatedCommand(for task: EncodingTask) -> String {
        guard let preset = task.preset else { return task.commandLine }
        let output = task.outputFile.isEmpty ? OutputPathBuilder.build(inputFile: task.inputFile, preset: preset) : task.outputFile
        return builder.build(preset: preset, input: task.inputFile, output: output)
    }

    private func handleOutput(_ line: String, task: EncodingTask?) {
        guard let task else { return }
        let now = Date()
        if now.timeIntervalSince(lastOutputUpdate[task.id] ?? .distantPast) > 0.15 {
            task.realtimeOutput = line
            lastOutputUpdate[task.id] = now
        }
        if parser.parse(line: line, into: &task.progress, startedAt: task.startedAt) {
            objectWillChange.send()
        } else {
            task.nonProgressOutput.append(line)
            if task.nonProgressOutput.count > 1000 {
                task.nonProgressOutput.removeFirst(task.nonProgressOutput.count - 100)
            }
        }
        if parser.isErrorLine(line) {
            task.errors.append(line)
        }
    }

    private func handleTermination(_ status: Int32, task: EncodingTask?) {
        guard let task else { return }
        guard !handledTerminations.contains(task.id) else { return }
        handledTerminations.insert(task.id)
        runningProcesses[task.id] = nil
        lastOutputUpdate[task.id] = nil
        task.completedAt = Date()
        if status == 0 {
            task.status = .completed
            task.progress.percent = 1
            if let preset = task.preset {
                MacSystemServices.preserveDates(from: task.inputFile, to: task.outputFile, preset: preset)
            }
        } else if task.wasManuallyStopped {
            task.status = .stopped
        } else {
            task.status = .failed
            deleteFailedOutputIfNeeded(task)
        }
        maybeStopSleepPreventer()
        if settingsStore.settings.autoStartTasks {
            startPending()
        }
    }

    private func deleteFailedOutputIfNeeded(_ task: EncodingTask) {
        guard !task.outputFile.isEmpty, FileManager.default.fileExists(atPath: task.outputFile), task.outputFile != task.inputFile else {
            return
        }
        switch settingsStore.settings.deleteFailedOutputPolicy {
        case 0:
            if URL(fileURLWithPath: task.outputFile).pathExtension.lowercased() == "mp4" {
                try? MacSystemServices.trashItem(path: task.outputFile)
            }
        case 1:
            try? MacSystemServices.trashItem(path: task.outputFile)
        default:
            break
        }
    }

    private func maybeStopSleepPreventer() {
        if !tasks.contains(where: { $0.status == .running || $0.status == .paused }) {
            sleepPreventer.stop()
        }
    }
}
