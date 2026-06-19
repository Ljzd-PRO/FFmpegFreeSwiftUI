import Foundation
import FFmpegFreeSwiftUI

public func makeFeatureCommandOnlyTests() -> [TestCase] {
    [
        TestCase("Feature queue", "Adds files with preset snapshot and custom output directory") { context in
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.autoStartTasks = false
                var preset = PresetData()
                preset.outputContainer = "mkv"
                preset.videoEncoder = "libx265"
                let store = EncodingQueueStore(settingsStore: settingsStore)
                store.addFiles(
                    [context.tempRoot.appendingPathComponent("input file.mp4").path],
                    preset: preset,
                    customOutputDirectory: context.tempRoot.appendingPathComponent("out", isDirectory: true).path
                )

                try expectEqual(store.tasks.count, 1, "one task should be added")
                let task = try requireTask(store.tasks.first, "task should exist")
                try expectEqual(task.displayName, "input file.mp4", "display name")
                try expectEqual(task.preset?.videoEncoder, "libx265", "preset snapshot")
                try expect(task.outputFile.hasSuffix("/out/input file.mkv"), "custom output directory should be used: \(task.outputFile)")
                try expectEqual(store.selectedTaskID, task.id, "first added task should become selected")
            }
        },
        TestCase("Feature queue", "Fake runner completes task and parses progress") { context in
            let fake = FakeFFmpegRunner(
                script: [
                    .output("Duration: 00:00:02.00, start: 0.000000, bitrate: 1000 kb/s"),
                    .output("frame=   20 fps=20 q=23.0 size=     100KiB time=00:00:01.00 bitrate=819.2kbits/s speed=1.0x"),
                    .finish(0)
                ]
            )
            final class StoreBox: @unchecked Sendable { var store: EncodingQueueStore? }
            let box = StoreBox()
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.autoStartTasks = false
                let store = EncodingQueueStore(settingsStore: settingsStore) { _, _ in fake }
                box.store = store
                store.addCommandTask(arguments: "-i in.mp4 -c copy out.mp4", displayName: "copy")
                try expectEqual(store.selectedTask?.status, .pending, "initial status")
                store.startSelected()
                try expectEqual(store.selectedTask?.status, .running, "running status")
            }

            try await waitUntil {
                await MainActor.run {
                    fake.handles.first?.waiterCount ?? 0 > 0
                }
            }

            try await runOnMainActor {
                guard let handle = fake.handles.first else { throw TestFailure("fake handle missing") }
                handle.flushAll()
            }

            try await waitUntil {
                await MainActor.run {
                    box.store?.selectedTask?.status == .completed
                }
            }

            try await runOnMainActor {
                guard let handle = fake.handles.first else { throw TestFailure("fake handle missing") }
                let task = try requireTask(box.store?.selectedTask, "selected task")
                try expectEqual(task.status, .completed, "completed status")
                try expectEqual(task.progress.quality, "23.0", "quality parsed")
                try expectEqual(task.progress.bitrate, "819.2 kbps", "bitrate parsed")
                try expectEqual(task.progress.speed, "1.0x", "speed parsed")
                try expectEqual(task.progress.percent, 1, "completion percent")
                try expectEqual(handle.argumentsLine, "-i in.mp4 -c copy out.mp4", "runner arguments")
                try expectEqual(handle.pauseCount, 0, "not paused")
            }
        },
        TestCase("Feature queue", "Pause resume stop and stdin use fake process") { context in
            let fake = FakeFFmpegRunner(script: [])
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.autoStartTasks = false
                let store = EncodingQueueStore(settingsStore: settingsStore) { _, _ in fake }
                store.addCommandTask(arguments: "-f lavfi -i testsrc -f null -", displayName: "long")
                store.startSelected()
                let task = try requireTask(store.selectedTask, "selected task")
                store.pause(task)
                try expectEqual(task.status, .paused, "paused")
                store.resume(task)
                try expectEqual(task.status, .running, "resumed")
                store.sendMessageToSelected("q")
                store.stop(task)
                try expectEqual(task.status, .stopped, "stopped immediately")
                guard let handle = fake.handles.first else { throw TestFailure("fake handle missing") }
                try expectEqual(handle.pauseCount, 1, "pause count")
                try expectEqual(handle.resumeCount, 1, "resume count")
                try expectEqual(handle.stopCount, 1, "stop count")
                try expectEqual(handle.messages, ["q"], "stdin messages")
            }
        },
        TestCase("Feature queue", "Failure captures error and reset clears transient state") { context in
            let fake = FakeFFmpegRunner(
                script: [
                    .output("Error while decoding stream #0:0: Invalid data found when processing input"),
                    .finish(1)
                ]
            )
            final class StoreBox: @unchecked Sendable { var store: EncodingQueueStore? }
            let box = StoreBox()
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.autoStartTasks = false
                let store = EncodingQueueStore(settingsStore: settingsStore) { _, _ in fake }
                box.store = store
                store.addCommandTask(arguments: "-i bad.mp4 out.mp4", displayName: "bad")
                store.startSelected()
                _ = try requireTask(store.selectedTask, "selected task")
            }
            try await runOnMainActor {
                guard let handle = fake.handles.first else { throw TestFailure("fake handle missing") }
                handle.flushAll()
            }
            try await waitUntil {
                await MainActor.run {
                    box.store?.selectedTask?.status == .failed
                }
            }
            try await runOnMainActor {
                let store = try requireTask(box.store, "store")
                let task = try requireTask(store.selectedTask, "selected task")
                try expectEqual(task.status, .failed, "failed status")
                try expect(!task.errors.isEmpty, "error line should be captured")
                store.reset(task)
                try expectEqual(task.status, .pending, "reset status")
                try expect(task.errors.isEmpty, "reset clears errors")
                try expect(task.nonProgressOutput.isEmpty, "reset clears output")
            }
        },
        TestCase("Feature queue", "Concurrent pending respects max slots and autostarts") { context in
            let fake = FakeFFmpegRunner(script: [.finish(0)])
            final class StoreBox: @unchecked Sendable { var store: EncodingQueueStore? }
            let box = StoreBox()
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.maxConcurrentTasks = 1
                settingsStore.settings.autoStartTasks = true
                let store = EncodingQueueStore(settingsStore: settingsStore) { _, _ in fake }
                box.store = store
                store.addCommandTask(arguments: "-i a out-a", displayName: "a")
                store.addCommandTask(arguments: "-i b out-b", displayName: "b")
                try expectEqual(store.tasks.map(\.status), [.running, .pending], "only one task should run")
                try expectEqual(fake.handles.count, 1, "one runner start")
            }
            try await waitUntil {
                await MainActor.run {
                    fake.handles.first?.waiterCount ?? 0 > 0
                }
            }
            try await runOnMainActor {
                fake.handles[0].flushAll()
            }
            try await waitUntil {
                await MainActor.run {
                    fake.handles.count == 2
                }
            }
        },
        TestCase("Feature queue", "Remote parser adds command and preset file tasks") { context in
            try await runOnMainActor {
                let presetURL = context.tempRoot.appendingPathComponent("remote.3fui")
                var preset = PresetData()
                preset.outputContainer = "mkv"
                try PresetIOService.save(preset, to: presetURL)

                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.autoStartTasks = false
                let queue = EncodingQueueStore(settingsStore: settingsStore)
                let server = RemoteCommandServer(queueStore: queue)
                server.parse(args: ["-ffmpeg", "-i", "/tmp/a b.mov", "-c:v", "copy", "/tmp/out file.mkv"])
                try expectEqual(queue.tasks.count, 1, "remote command task")
                try expectContains(queue.tasks[0].commandLine, "\"/tmp/a b.mov\"", "remote command should preserve quoted input")
                try expectContains(queue.tasks[0].commandLine, "\"/tmp/out file.mkv\"", "remote command should preserve quoted output")

                server.parse(args: ["-i", "/tmp/input.mov", "-3fui_file", presetURL.path])
                try expectEqual(queue.tasks.count, 2, "remote preset task")
                try expectEqual(queue.tasks[1].inputFile, "/tmp/input.mov", "remote preset input")
                try expectEqual(queue.tasks[1].preset?.outputContainer, "mkv", "remote preset loaded")
                try expectEqual(RemoteCommandServer.normalizedPort(""), "10591", "empty port default")
                try expectEqual(RemoteCommandServer.normalizedPort("10590"), "10591", "legacy port remap")
            }
        },
        TestCase("Feature tools", "FFprobe and ffplay use locator paths and working directory") { context in
            let tools = try makeFakeTools(context: context)
            let launcher = RecordingToolLauncher(capturingOutput: "Input #0, mov, from 'sample.mp4'")
            var settings = AppSettings()
            settings.ffmpegExecutableOverride = tools.appendingPathComponent("ffmpeg").path
            settings.workingDirectory = context.tempRoot.path
            let service = FFprobeService(locator: FFmpegLocator(settings: settings), settings: settings, launcher: launcher)
            let output = try await service.probe(file: "/tmp/media file.mp4")
            try expectContains(output, "Input #0", "probe output")
            try service.play(file: "/tmp/media file.mp4")
            try expectEqual(launcher.capturedRequests.count, 1, "one captured request")
            try expectEqual(launcher.detachedRequests.count, 1, "one detached request")
            try expectEqual(launcher.capturedRequests[0].executable, tools.appendingPathComponent("ffprobe").path, "ffprobe path")
            try expectEqual(launcher.capturedRequests[0].arguments, ["-hide_banner", "/tmp/media file.mp4"], "ffprobe args")
            try expectEqual(launcher.detachedRequests[0].executable, tools.appendingPathComponent("ffplay").path, "ffplay path")
            try expectEqual(launcher.detachedRequests[0].workingDirectory, context.tempRoot.path, "working directory")
        },
        TestCase("Feature quality store", "Enqueues tasks and preserves history in injected file") { context in
            try await runOnMainActor {
                let historyURL = context.tempRoot.appendingPathComponent("quality-history.json")
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                let store = QualityAssessmentStore(settingsStore: settingsStore, historyURL: historyURL, autoStart: false)
                store.enqueue(
                    referenceFile: "/tmp/ref.mp4",
                    distortedFiles: ["/tmp/a.mp4", " ", "/tmp/b.mp4"],
                    metrics: [.psnr, .ssim],
                    configuration: QualityAssessmentConfiguration(duration: "1"),
                    resetQueue: true
                )
                try expectEqual(store.statusMessage, "已加入测评队列", "enqueue message")
                try expectEqual(store.tasks.count, 2, "two quality tasks")
                try expectEqual(store.tasks[0].metrics, [.psnr, .ssim], "metrics")
                store.results = [
                    QualityAssessmentResult(referenceFile: "/tmp/ref.mp4", distortedFile: "/tmp/a.mp4", metric: .psnr, score: "42")
                ]
                store.clearHistory()
                try expectEqual(store.results.count, 0, "history cleared")
                try expect(FileManager.default.fileExists(atPath: historyURL.path), "injected history file should be used")
                store.resetPageState()
                try expectEqual(store.tasks.count, 0, "reset clears tasks")
                try expectEqual(store.statusMessage, "页面已重置，历史结果已保留", "reset message")
            }
        },
        TestCase("Feature quality store", "Unavailable filters mark task failed without running ffmpeg") { context in
            final class StoreBox: @unchecked Sendable { var store: QualityAssessmentStore? }
            let box = StoreBox()
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                let store = QualityAssessmentStore(
                    settingsStore: settingsStore,
                    historyURL: context.tempRoot.appendingPathComponent("quality-history.json"),
                    autoStart: false
                )
                box.store = store
                store.filterAvailability = QualityFilterAvailability(available: [.psnr], unavailableReasons: [.vmaf: "libvmaf missing"])
                store.enqueue(
                    referenceFile: "/tmp/ref.mp4",
                    distortedFiles: ["/tmp/dist.mp4"],
                    metrics: [.vmaf],
                    configuration: QualityAssessmentConfiguration(),
                    resetQueue: true
                )
                store.startIfNeeded()
            }
            try await waitUntil {
                await MainActor.run {
                    box.store?.tasks.first?.status == .failed
                }
            }
            try await runOnMainActor {
                let task = try requireTask(box.store?.tasks.first, "quality task")
                try expectEqual(task.errors, ["libvmaf missing"], "unavailable reason")
                try expectEqual(task.status, .failed, "quality task should fail")
            }
        },
        TestCase("Feature mux merge", "Muxing unique metadata choices and queue command task") { context in
            try await runOnMainActor {
                let settingsStore = SettingsStore(url: context.tempRoot.appendingPathComponent("settings.json"))
                settingsStore.settings.autoStartTasks = false
                let queue = EncodingQueueStore(settingsStore: settingsStore)
                let inputs = [
                    MuxingInput(path: "/tmp/video.mkv", videoStreams: "0, 1", audioStreams: "0", usesChapters: true),
                    MuxingInput(path: "/tmp/audio.mka", audioStreams: "0", subtitleStreams: "0", usesMetadata: true)
                ]
                let command = MuxingCommandBuilder().build(inputs: inputs, output: "/tmp/muxed out.mkv")
                queue.addCommandTask(arguments: command, displayName: "混流任务", outputPath: "/tmp/muxed out.mkv")
                try expectEqual(queue.tasks.count, 1, "mux task queued")
                try expectContains(queue.tasks[0].commandLine, "-map_chapters 0", "chapter source")
                try expectContains(queue.tasks[0].commandLine, "-map_metadata 1", "metadata source")
                try expectContains(queue.tasks[0].commandLine, "-map 1:s:0 -c:s copy", "subtitle stream")
            }
        },
        TestCase("Feature mux merge", "Merging writes concat file to requested directory") { context in
            let builder = MergingCommandBuilder()
            let list = try builder.writeConcatFile(files: ["/tmp/a one.mp4", "/tmp/b'two.mp4"], directory: context.tempRoot)
            let body = try String(contentsOf: list, encoding: .utf8)
            try expect(list.path.hasPrefix(context.tempRoot.path), "concat file should be in temp root")
            try expectContains(body, "file '/tmp/a one.mp4'", "first concat item")
            try expectContains(body, "file '/tmp/b'\\''two.mp4'", "escaped quote")
        },
        TestCase("Feature settings", "Debounced settings save writes display and language choices") { context in
            let url = context.tempRoot.appendingPathComponent("settings.json")
            try await runOnMainActor {
                let store = SettingsStore(url: url)
                store.settings.language = AppLanguage.traditionalChinese.rawValue
                store.settings.appearanceMode = AppAppearanceMode.dark.rawValue
                store.settings.interfaceDensity = AppInterfaceDensity.compact.rawValue
                store.settings.baseFontSize = 16
                store.save()
            }
            try await waitUntil(timeout: 3) {
                FileManager.default.fileExists(atPath: url.path)
            }
            let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(contentsOf: url))
            try expectEqual(decoded.language, AppLanguage.traditionalChinese.rawValue, "language persisted")
            try expectEqual(decoded.appearanceMode, AppAppearanceMode.dark.rawValue, "appearance persisted")
            try expectEqual(decoded.interfaceDensity, AppInterfaceDensity.compact.rawValue, "density persisted")
            try expectEqual(decoded.baseFontSize, 16, "font size persisted")
        },
        TestCase("Feature settings", "Locator derives all tools from custom ffmpeg path") { context in
            let tools = try makeFakeTools(context: context)
            var settings = AppSettings()
            settings.ffmpegExecutableOverride = tools.appendingPathComponent("ffmpeg").path
            let locator = FFmpegLocator(settings: settings)
            try expectEqual(locator.locate(.ffmpeg), tools.appendingPathComponent("ffmpeg").path, "ffmpeg override")
            try expectEqual(locator.locate(.ffprobe), tools.appendingPathComponent("ffprobe").path, "ffprobe sibling")
            try expectEqual(locator.locate(.ffplay), tools.appendingPathComponent("ffplay").path, "ffplay sibling")
        },
        TestCase("Feature localization", "Navigation and feature labels localize across languages") { _ in
            try expectEqual(L10n.text("画质评测", language: "en"), "Quality Assessment", "English quality assessment")
            try expectEqual(L10n.text("混流", language: "en"), "Muxing", "English muxing")
            try expectEqual(L10n.text("合并", language: "zh-Hant"), "合併", "Traditional merging")
            try expectEqual(L10n.text("性能监控", language: "zh-Hant"), "性能監控", "Traditional performance")
        },
        TestCase("Feature performance", "Snapshot values stay in valid ranges") { _ in
            let monitor = PerformanceMonitor()
            let first = await monitor.snapshot(runningQueueTasks: 2, pendingQueueTasks: 3)
            try await Task.sleep(nanoseconds: 150_000_000)
            let second = await monitor.snapshot(runningQueueTasks: 2, pendingQueueTasks: 3)
            try expect((0...1).contains(second.cpuUsage), "cpu usage range")
            try expect(second.coreUsages.allSatisfy { (0...1).contains($0) }, "core usage range")
            try expect((0...1).contains(second.memoryUsage), "memory usage range")
            try expect((0...1).contains(second.diskUsage), "disk usage range")
            try expectEqual(second.runningQueueTasks, 2, "running count")
            try expectEqual(second.pendingQueueTasks, 3, "pending count")
            try expect(second.sampledAt >= first.sampledAt, "sample time should move forward")
        }
    ]
}

private func requireTask<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
        throw TestFailure(message)
    }
    return value
}

private func makeFakeTools(context: TestContext) throws -> URL {
    let directory = context.tempRoot.appendingPathComponent("fake-tools", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for name in ["ffmpeg", "ffprobe", "ffplay"] {
        let url = directory.appendingPathComponent(name)
        try "#!/bin/sh\nexit 0\n".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
    return directory
}

private final class FakeFFmpegRunner: FFmpegProcessLaunching, @unchecked Sendable {
    enum Step: Sendable {
        case output(String)
        case finish(Int32)
    }

    let script: [Step]
    var handles: [FakeFFmpegProcess] = []

    init(script: [Step]) {
        self.script = script
    }

    func run(
        argumentsLine: String,
        outputHandler: @escaping @Sendable (String) -> Void,
        terminationHandler: @escaping @Sendable (Int32) -> Void
    ) throws -> any FFmpegProcessHandle {
        let handle = FakeFFmpegProcess(
            argumentsLine: argumentsLine,
            script: script,
            outputHandler: outputHandler,
            terminationHandler: terminationHandler
        )
        handles.append(handle)
        return handle
    }
}

private final class FakeFFmpegProcess: FFmpegProcessHandle, @unchecked Sendable {
    let argumentsLine: String
    let processIdentifier: Int32
    private let script: [FakeFFmpegRunner.Step]
    private let outputHandler: @Sendable (String) -> Void
    private let terminationHandler: @Sendable (Int32) -> Void
    private var continuation: CheckedContinuation<Int32, Never>?
    private var finishedStatus: Int32?
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var stopCount = 0
    private(set) var messages: [String] = []
    private(set) var isFinished = false
    private(set) var terminationRequested = false
    private(set) var waiterCount = 0

    init(
        argumentsLine: String,
        script: [FakeFFmpegRunner.Step],
        outputHandler: @escaping @Sendable (String) -> Void,
        terminationHandler: @escaping @Sendable (Int32) -> Void
    ) {
        self.argumentsLine = argumentsLine
        self.script = script
        self.outputHandler = outputHandler
        self.terminationHandler = terminationHandler
        self.processIdentifier = Int32(Int.random(in: 10_000...30_000))
    }

    func waitUntilExitStatus() async -> Int32 {
        waiterCount += 1
        if let finishedStatus {
            return finishedStatus
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func flushAll() {
        for step in script {
            switch step {
            case let .output(line):
                outputHandler(line)
            case let .finish(status):
                finish(status)
            }
        }
    }

    func finish(_ status: Int32) {
        guard !isFinished else { return }
        isFinished = true
        finishedStatus = status
        terminationRequested = true
        terminationHandler(status)
        continuation?.resume(returning: status)
        continuation = nil
    }

    func send(_ message: String) {
        messages.append(message)
    }

    func pause() {
        pauseCount += 1
    }

    func resume() {
        resumeCount += 1
    }

    func stop() {
        stopCount += 1
        finish(255)
    }
}

private final class RecordingToolLauncher: ToolProcessLaunching, @unchecked Sendable {
    var capturedRequests: [ToolProcessRequest] = []
    var detachedRequests: [ToolProcessRequest] = []
    var capturingOutput: String
    var error: Error?

    init(capturingOutput: String) {
        self.capturingOutput = capturingOutput
    }

    func runCapturing(_ request: ToolProcessRequest) async throws -> String {
        capturedRequests.append(request)
        if let error {
            throw error
        }
        return capturingOutput
    }

    func runDetached(_ request: ToolProcessRequest) throws {
        detachedRequests.append(request)
        if let error {
            throw error
        }
    }
}
