import Foundation

@MainActor
public final class QualityAssessmentStore: ObservableObject {
    @Published public var tasks: [QualityAssessmentTask] = []
    @Published public var selectedTaskID: QualityAssessmentTask.ID?
    @Published public var results: [QualityAssessmentResult] = []
    @Published public var filterAvailability = QualityFilterAvailability()
    @Published public var statusMessage = ""
    @Published public var isRunning = false

    private let settingsStore: SettingsStore
    private var workerTask: Task<Void, Never>?
    private var probeTask: Task<Void, Never>?
    private let historyURL: URL

    public init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        historyURL = Self.defaultHistoryURL()
        loadHistory()
    }

    public var selectedTask: QualityAssessmentTask? {
        guard let selectedTaskID else { return tasks.first }
        return tasks.first { $0.id == selectedTaskID }
    }

    public func refreshFilterAvailability() {
        probeTask?.cancel()
        let settings = settingsStore.settings
        probeTask = Task { [weak self] in
            let availability = await QualityAssessmentRunner(locator: FFmpegLocator(settings: settings)).probeFilters()
            await MainActor.run {
                self?.filterAvailability = availability
            }
        }
    }

    public func enqueue(
        referenceFile: String,
        distortedFiles: [String],
        metrics: [QualityMetric],
        configuration: QualityAssessmentConfiguration,
        resetQueue: Bool
    ) {
        let cleanReference = referenceFile.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanFiles = distortedFiles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let cleanMetrics = metrics.isEmpty ? [.psnr] : metrics
        guard !cleanReference.isEmpty, !cleanFiles.isEmpty else {
            statusMessage = "请先选择原视频和编码后的文件"
            return
        }
        if resetQueue {
            stop()
            tasks.removeAll()
            selectedTaskID = nil
        }
        for file in cleanFiles {
            let task = QualityAssessmentTask(
                referenceFile: cleanReference,
                distortedFile: file,
                metrics: cleanMetrics,
                configuration: configuration
            )
            tasks.append(task)
            if selectedTaskID == nil {
                selectedTaskID = task.id
            }
        }
        statusMessage = "已加入测评队列"
        startIfNeeded()
    }

    public func startIfNeeded() {
        guard workerTask == nil else { return }
        workerTask = Task { [weak self] in
            await self?.runQueue()
        }
    }

    public func stop() {
        workerTask?.cancel()
        workerTask = nil
        isRunning = false
        for task in tasks where task.status == .running {
            task.status = .stopped
            task.completedAt = Date()
        }
        statusMessage = "已停止测评"
    }

    public func resetPageState() {
        stop()
        tasks.removeAll()
        selectedTaskID = nil
        statusMessage = "页面已重置，历史结果已保留"
    }

    public func clearHistory() {
        results.removeAll()
        saveHistory()
        statusMessage = "历史结果已清空"
    }

    public func copyResult(_ result: QualityAssessmentResult) {
        let text = [
            "指标: \(result.metric.rawValue)",
            "原视频: \(result.referenceFile)",
            "编码后: \(result.distortedFile)",
            "分数: \(result.score)",
            "平均: \(result.average)",
            "最低: \(result.minimum)",
            "日志: \(result.logPath)"
        ].joined(separator: "\n")
        MacSystemServices.copyToPasteboard(text)
    }

    public func revealLog(_ result: QualityAssessmentResult) {
        guard !result.logPath.isEmpty else { return }
        MacSystemServices.revealInFinder(path: result.logPath)
    }

    private func runQueue() async {
        isRunning = true
        defer {
            workerTask = nil
            isRunning = false
        }

        while !Task.isCancelled {
            guard let task = tasks.first(where: { $0.status == .pending }) else {
                statusMessage = "测评队列已完成"
                return
            }
            await run(task)
        }
    }

    private func run(_ task: QualityAssessmentTask) async {
        task.status = .running
        task.startedAt = Date()
        task.completedAt = nil
        task.errors.removeAll()
        task.results.removeAll()
        let runner = QualityAssessmentRunner(locator: FFmpegLocator(settings: settingsStore.settings))
        let started = Date()

        for metric in task.metrics {
            guard !Task.isCancelled else {
                task.status = .stopped
                task.completedAt = Date()
                return
            }
            if !filterAvailability.available.isEmpty, !filterAvailability.isAvailable(metric) {
                task.errors.append(filterAvailability.unavailableReasons[metric] ?? "\(metric.rawValue) 滤镜不可用")
                continue
            }
            task.currentMetric = metric
            do {
                let result = try await runner.run(
                    metric: metric,
                    referenceFile: task.referenceFile,
                    distortedFile: task.distortedFile,
                    configuration: task.configuration
                ) { [weak task] line in
                    Task { @MainActor in
                        task?.realtimeOutput = line
                    }
                }
                task.results.append(result)
                results.insert(result, at: 0)
                saveHistory()
            } catch {
                task.errors.append(error.localizedDescription)
            }
        }

        task.currentMetric = nil
        task.completedAt = Date()
        if Task.isCancelled {
            task.status = .stopped
        } else if task.results.isEmpty && !task.errors.isEmpty {
            task.status = .failed
            statusMessage = "测评失败"
        } else {
            task.status = .completed
            statusMessage = "测评完成，用时 \(FileSizeFormatting.durationText(Date().timeIntervalSince(started)))"
        }
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let decoded = try? JSONDecoder().decode([QualityAssessmentResult].self, from: data) else {
            return
        }
        results = decoded
    }

    private func saveHistory() {
        do {
            try FileManager.default.createDirectory(
                at: historyURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(Array(results.prefix(500))).write(to: historyURL, options: .atomic)
        } catch {
            statusMessage = "保存测评历史失败: \(error.localizedDescription)"
        }
    }

    private static func defaultHistoryURL() -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return root
            .appendingPathComponent("FFmpegFreeSwiftUI", isDirectory: true)
            .appendingPathComponent("quality-assessment-history.json")
    }
}
