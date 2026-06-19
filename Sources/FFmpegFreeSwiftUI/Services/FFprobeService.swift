import Foundation

public struct ToolProcessRequest: Equatable, Sendable {
    public var executable: String
    public var arguments: [String]
    public var workingDirectory: String

    public init(executable: String, arguments: [String], workingDirectory: String = "") {
        self.executable = executable
        self.arguments = arguments
        self.workingDirectory = workingDirectory
    }
}

public protocol ToolProcessLaunching: Sendable {
    func runCapturing(_ request: ToolProcessRequest) async throws -> String
    func runDetached(_ request: ToolProcessRequest) throws
}

public struct FoundationToolProcessLauncher: ToolProcessLaunching {
    public init() {}

    public func runCapturing(_ request: ToolProcessRequest) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: request.executable)
            process.arguments = request.arguments
            if !request.workingDirectory.isEmpty {
                process.currentDirectoryURL = URL(fileURLWithPath: request.workingDirectory)
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
                    continuation.resume(throwing: RuntimeError(text.isEmpty ? "process failed" : text))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func runDetached(_ request: ToolProcessRequest) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: request.executable)
        process.arguments = request.arguments
        if !request.workingDirectory.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: request.workingDirectory)
        }
        try process.run()
    }
}

public struct FFprobeService {
    public var locator: FFmpegLocator
    public var settings: AppSettings
    public var launcher: any ToolProcessLaunching

    public init(locator: FFmpegLocator, settings: AppSettings, launcher: any ToolProcessLaunching = FoundationToolProcessLauncher()) {
        self.locator = locator
        self.settings = settings
        self.launcher = launcher
    }

    public func probe(file: String) async throws -> String {
        try await run(tool: .ffprobe, arguments: ["-hide_banner", file])
    }

    public func play(file: String) throws {
        try launcher.runDetached(request(tool: .ffplay, arguments: [file]))
    }

    private func run(tool: FFmpegTool, arguments: [String]) async throws -> String {
        try await launcher.runCapturing(request(tool: tool, arguments: arguments))
    }

    private func request(tool: FFmpegTool, arguments: [String]) -> ToolProcessRequest {
        ToolProcessRequest(executable: locator.locate(tool), arguments: arguments, workingDirectory: settings.workingDirectory)
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
