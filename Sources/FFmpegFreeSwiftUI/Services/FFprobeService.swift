import Foundation

public struct FFprobeService {
    public var locator: FFmpegLocator
    public var settings: AppSettings

    public init(locator: FFmpegLocator, settings: AppSettings) {
        self.locator = locator
        self.settings = settings
    }

    public func probe(file: String) async throws -> String {
        try await run(tool: .ffprobe, arguments: ["-hide_banner", file])
    }

    public func play(file: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: locator.locate(.ffplay))
        process.arguments = [file]
        if !settings.workingDirectory.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: settings.workingDirectory)
        }
        try process.run()
    }

    private func run(tool: FFmpegTool, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: locator.locate(tool))
            process.arguments = arguments
            if !settings.workingDirectory.isEmpty {
                process.currentDirectoryURL = URL(fileURLWithPath: settings.workingDirectory)
            }
            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr
            process.terminationHandler = { process in
                let out = stdout.fileHandleForReading.readDataToEndOfFile()
                let err = stderr.fileHandleForReading.readDataToEndOfFile()
                let text = (String(data: out, encoding: .utf8) ?? "") + (String(data: err, encoding: .utf8) ?? "")
                if process.terminationStatus == 0 {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(throwing: RuntimeError(text.isEmpty ? "ffprobe failed" : text))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

public struct RuntimeError: LocalizedError, Sendable {
    public var message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}
