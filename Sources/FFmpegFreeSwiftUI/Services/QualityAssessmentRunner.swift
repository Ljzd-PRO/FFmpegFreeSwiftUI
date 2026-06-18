import Foundation

public struct QualityFilterAvailability: Equatable, Sendable {
    public var available: Set<QualityMetric>
    public var unavailableReasons: [QualityMetric: String]

    public init(available: Set<QualityMetric> = [], unavailableReasons: [QualityMetric: String] = [:]) {
        self.available = available
        self.unavailableReasons = unavailableReasons
    }

    public func isAvailable(_ metric: QualityMetric) -> Bool {
        available.contains(metric)
    }
}

public struct QualityAssessmentCommand: Equatable, Sendable {
    public var arguments: [String]
    public var logPath: String

    public init(arguments: [String], logPath: String) {
        self.arguments = arguments
        self.logPath = logPath
    }

    public var argumentsLine: String {
        ShellQuoting.joinArguments(arguments)
    }
}

public struct QualityAssessmentRunner: Sendable {
    public var locator: FFmpegLocator

    public init(locator: FFmpegLocator) {
        self.locator = locator
    }

    public static func outputDirectory(for configuration: QualityAssessmentConfiguration, referenceFile: String) -> URL {
        if !configuration.outputDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(fileURLWithPath: configuration.outputDirectory, isDirectory: true)
        }
        let referenceURL = URL(fileURLWithPath: referenceFile)
        return referenceURL.deletingLastPathComponent()
    }

    public static func command(
        metric: QualityMetric,
        referenceFile: String,
        distortedFile: String,
        configuration: QualityAssessmentConfiguration,
        logDirectory: URL
    ) -> QualityAssessmentCommand {
        let logPath = logPathFor(metric: metric, distortedFile: distortedFile, directory: logDirectory)
        var arguments = ["-hide_banner", "-nostdin"]
        if !configuration.startTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            arguments += ["-ss", configuration.startTime]
        }
        if !configuration.duration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            arguments += ["-t", configuration.duration]
        }
        arguments += ["-i", distortedFile, "-i", referenceFile]
        if !configuration.sampleInterval.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            arguments += ["-filter_complex", sampledFilter(metric: metric, configuration: configuration, logPath: logPath)]
        } else {
            arguments += ["-lavfi", filter(metric: metric, configuration: configuration, logPath: logPath)]
        }
        arguments += ["-f", "null", "-"]
        return QualityAssessmentCommand(arguments: arguments, logPath: logPath)
    }

    public static func parseResult(
        metric: QualityMetric,
        output: String,
        logPath: String,
        referenceFile: String,
        distortedFile: String,
        elapsedSeconds: TimeInterval
    ) -> QualityAssessmentResult {
        let logText = (try? String(contentsOfFile: logPath, encoding: .utf8)) ?? ""
        let combined = [output, logText].filter { !$0.isEmpty }.joined(separator: "\n")
        let score: String
        let average: String
        let minimum: String
        switch metric {
        case .psnr:
            score = match(#"average:\s*([A-Za-z0-9\.\+\-]+)"#, in: combined) ?? "N/A"
            average = score
            minimum = match(#"min:\s*([A-Za-z0-9\.\+\-]+)"#, in: combined)
                ?? minValue(from: combined, key: "psnr_avg")
                ?? "N/A"
        case .xpsnr:
            score = match(#"XPSNR[^\n]*average[^\d\-]*([\d\.\-]+)"#, in: combined)
                ?? match(#"xpsnr_avg:\s*([\d\.\-]+)"#, in: combined)
                ?? lastNumericValue(in: combined)
                ?? "N/A"
            average = score
            minimum = minValue(from: combined, key: "xpsnr_avg") ?? "N/A"
        case .ssim:
            score = match(#"All:\s*([\d\.\-]+)"#, in: combined) ?? "N/A"
            average = score
            minimum = minValue(from: combined, key: "All") ?? "N/A"
        case .vmaf:
            score = match(#""mean"\s*:\s*([\d\.\-]+)"#, in: combined)
                ?? match(#"VMAF score:\s*([\d\.\-]+)"#, in: combined)
                ?? "N/A"
            average = score
            minimum = match(#""min"\s*:\s*([\d\.\-]+)"#, in: combined) ?? "N/A"
        }
        return QualityAssessmentResult(
            referenceFile: referenceFile,
            distortedFile: distortedFile,
            metric: metric,
            score: score,
            average: average,
            minimum: minimum,
            logPath: logPath,
            elapsedSeconds: elapsedSeconds,
            completedAt: Date(),
            rawSummary: combined
        )
    }

    public func probeFilters() async -> QualityFilterAvailability {
        let ffmpeg = locator.locate(.ffmpeg)
        let output = await runText(path: ffmpeg, arguments: ["-hide_banner", "-filters"], timeout: 5)
        guard !output.isEmpty else {
            return QualityFilterAvailability(
                available: [],
                unavailableReasons: Dictionary(uniqueKeysWithValues: QualityMetric.allCases.map {
                    ($0, "无法运行 ffmpeg -filters")
                })
            )
        }
        var available = Set<QualityMetric>()
        var reasons: [QualityMetric: String] = [:]
        for metric in QualityMetric.allCases {
            if filterList(output, contains: metric.filterName) {
                available.insert(metric)
            } else {
                reasons[metric] = "\(metric.rawValue) 滤镜不可用，请确认本机 ffmpeg 编译包含 \(metric.filterName)"
            }
        }
        return QualityFilterAvailability(available: available, unavailableReasons: reasons)
    }

    public func run(
        metric: QualityMetric,
        referenceFile: String,
        distortedFile: String,
        configuration: QualityAssessmentConfiguration,
        outputHandler: @escaping @Sendable (String) -> Void
    ) async throws -> QualityAssessmentResult {
        let outputDirectory = Self.outputDirectory(for: configuration, referenceFile: referenceFile)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let command = Self.command(
            metric: metric,
            referenceFile: referenceFile,
            distortedFile: distortedFile,
            configuration: configuration,
            logDirectory: outputDirectory
        )
        let started = Date()
        let output = try await runProcess(arguments: command.arguments, outputHandler: outputHandler)
        return Self.parseResult(
            metric: metric,
            output: output,
            logPath: command.logPath,
            referenceFile: referenceFile,
            distortedFile: distortedFile,
            elapsedSeconds: Date().timeIntervalSince(started)
        )
    }

    private static func filter(metric: QualityMetric, configuration: QualityAssessmentConfiguration, logPath: String) -> String {
        switch metric {
        case .psnr:
            return "[0:v][1:v]psnr=stats_file=\(escapeFilterValue(logPath))"
        case .xpsnr:
            return "[0:v][1:v]xpsnr=stats_file=\(escapeFilterValue(logPath))"
        case .ssim:
            return "[0:v][1:v]ssim=stats_file=\(escapeFilterValue(logPath))"
        case .vmaf:
            var parts = ["log_path=\(escapeFilterValue(logPath))", "log_fmt=json"]
            if !configuration.vmafModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("model_path=\(escapeFilterValue(configuration.vmafModel))")
            }
            if !configuration.vmafPool.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("pool=\(configuration.vmafPool)")
            }
            return "[0:v][1:v]libvmaf=\(parts.joined(separator: ":"))"
        }
    }

    private static func sampledFilter(metric: QualityMetric, configuration: QualityAssessmentConfiguration, logPath: String) -> String {
        let interval = configuration.sampleInterval.trimmingCharacters(in: .whitespacesAndNewlines)
        let selector = interval.isEmpty ? "1" : "not(mod(n\\,\(interval)))"
        let metricFilter = filter(metric: metric, configuration: configuration, logPath: logPath)
        return "[0:v]select='\(selector)',setpts=N/FRAME_RATE/TB[dist];[1:v]select='\(selector)',setpts=N/FRAME_RATE/TB[ref];[dist][ref]\(metricFilter.replacingOccurrences(of: "[0:v][1:v]", with: ""))"
    }

    private static func logPathFor(metric: QualityMetric, distortedFile: String, directory: URL) -> String {
        let base = URL(fileURLWithPath: distortedFile).deletingPathExtension().lastPathComponent
        let ext = metric == .vmaf ? "json" : "log"
        return directory.appendingPathComponent("\(base)-\(metric.filterName)-\(timestamp()).\(ext)").path
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private static func escapeFilterValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ":", with: "\\:")
            .replacingOccurrences(of: "'", with: "\\'")
    }

    private static func match(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func minValue(from text: String, key: String) -> String? {
        let values = matches(#"\#(key):\s*([\d\.\-]+)"#, in: text).compactMap(Double.init)
        guard let min = values.min() else { return nil }
        return String(format: "%.6g", min)
    }

    private static func lastNumericValue(in text: String) -> String? {
        matches(#"([\d]+\.[\d]+)"#, in: text).last
    }

    private static func matches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    private func filterList(_ output: String, contains filter: String) -> Bool {
        output.split(whereSeparator: \.isNewline).contains { line in
            line.split(separator: " ").contains { $0 == filter }
        }
    }

    private func runText(path: String, arguments: [String], timeout: TimeInterval) async -> String {
        do {
            return try await runProcess(path: path, arguments: arguments, timeout: timeout)
        } catch {
            return ""
        }
    }

    private func runProcess(arguments: [String], outputHandler: @escaping @Sendable (String) -> Void) async throws -> String {
        try await runProcess(path: locator.locate(.ffmpeg), arguments: arguments, timeout: 60 * 60, outputHandler: outputHandler)
    }

    private func runProcess(path: String, arguments: [String], timeout: TimeInterval) async throws -> String {
        try await runProcess(path: path, arguments: arguments, timeout: timeout, outputHandler: { _ in })
    }

    private func runProcess(
        path: String,
        arguments: [String],
        timeout: TimeInterval,
        outputHandler: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let processBox = RunningProcessBox()
        return try await withTaskCancellationHandler {
            try await Task.detached(priority: .utility) {
                try runProcessSynchronously(
                    path: path,
                    arguments: arguments,
                    timeout: timeout,
                    processBox: processBox,
                    outputHandler: outputHandler
                )
            }.value
        } onCancel: {
            processBox.terminate()
        }
    }

    private func runProcessSynchronously(
        path: String,
        arguments: [String],
        timeout: TimeInterval,
        processBox: RunningProcessBox,
        outputHandler: @escaping @Sendable (String) -> Void
    ) throws -> String {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try process.run()
            processBox.set(process)

            var output = Data()
            let reader = Task.detached(priority: .utility) {
                var text = ""
                while process.isRunning {
                    let data = pipe.fileHandleForReading.availableData
                    if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                        text += chunk
                        for line in chunk.split(whereSeparator: \.isNewline) {
                            outputHandler(String(line))
                        }
                    }
                    usleep(50_000)
                }
                let tail = pipe.fileHandleForReading.readDataToEndOfFile()
                if !tail.isEmpty, let chunk = String(data: tail, encoding: .utf8) {
                    text += chunk
                    for line in chunk.split(whereSeparator: \.isNewline) {
                        outputHandler(String(line))
                    }
                }
                return text
            }

            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning && Date() < deadline {
                usleep(100_000)
            }
            if process.isRunning {
                process.terminate()
                usleep(200_000)
                if process.isRunning {
                    Darwin.kill(process.processIdentifier, SIGKILL)
                }
            }
            let text = waitForReader(reader)
            output.append(Data(text.utf8))
            guard process.terminationStatus == 0 else {
                throw QualityAssessmentError.processFailed(status: process.terminationStatus, output: text)
            }
            return text
    }

    private func waitForReader(_ task: Task<String, Never>) -> String {
        let semaphore = DispatchSemaphore(value: 0)
        final class Box: @unchecked Sendable { var value = "" }
        let box = Box()
        Task {
            box.value = await task.value
            semaphore.signal()
        }
        semaphore.wait()
        return box.value
    }
}

private final class RunningProcessBox: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?

    func set(_ process: Process) {
        lock.lock()
        self.process = process
        lock.unlock()
    }

    func terminate() {
        lock.lock()
        let process = process
        lock.unlock()
        guard let process, process.isRunning else { return }
        process.terminate()
        usleep(200_000)
        if process.isRunning {
            Darwin.kill(process.processIdentifier, SIGKILL)
        }
    }
}

public enum QualityAssessmentError: Error, LocalizedError, Sendable {
    case processFailed(status: Int32, output: String)

    public var errorDescription: String? {
        switch self {
        case let .processFailed(status, output):
            return "画质评测失败，退出码 \(status)\n\(output)"
        }
    }
}
