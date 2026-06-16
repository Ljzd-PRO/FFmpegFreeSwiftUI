import Foundation

public final class FFmpegRunningProcess {
    public let process: Process
    public let stdinPipe: Pipe

    public init(process: Process, stdinPipe: Pipe) {
        self.process = process
        self.stdinPipe = stdinPipe
    }

    public var processIdentifier: Int32 {
        process.processIdentifier
    }

    public func send(_ message: String) {
        guard let data = (message + "\n").data(using: .utf8) else { return }
        stdinPipe.fileHandleForWriting.write(data)
    }

    public func pause() {
        Darwin.kill(process.processIdentifier, SIGSTOP)
    }

    public func resume() {
        Darwin.kill(process.processIdentifier, SIGCONT)
    }

    public func stop() {
        if process.isRunning {
            process.terminate()
        }
    }

    public func forceStop() {
        if process.isRunning {
            process.interrupt()
            Darwin.kill(process.processIdentifier, SIGKILL)
        }
    }
}

public struct FFmpegRunner {
    public var locator: FFmpegLocator
    public var settings: AppSettings

    public init(locator: FFmpegLocator, settings: AppSettings) {
        self.locator = locator
        self.settings = settings
    }

    public func run(
        argumentsLine: String,
        outputHandler: @escaping @Sendable (String) -> Void,
        terminationHandler: @escaping @Sendable (Int32) -> Void
    ) throws -> FFmpegRunningProcess {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: locator.locate(.ffmpeg))
        var arguments = ShellQuoting.splitArguments(argumentsLine)
        if !settings.argumentPassthroughTemplate.isEmpty {
            let replaced = settings.argumentPassthroughTemplate.replacingOccurrences(of: "<args>", with: argumentsLine)
            arguments = ShellQuoting.splitArguments(replaced)
        }
        process.arguments = arguments
        if !settings.workingDirectory.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: settings.workingDirectory)
        }

        let stdout = Pipe()
        let stderr = Pipe()
        let stdin = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        process.standardInput = stdin

        let outputQueue = DispatchQueue(label: "top.ffmpegfreeui.runner.output", qos: .utility)
        let readHandler: (FileHandle) -> Void = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            outputQueue.async {
                for line in text.split(whereSeparator: \.isNewline) {
                    outputHandler(String(line))
                }
            }
        }
        stdout.fileHandleForReading.readabilityHandler = readHandler
        stderr.fileHandleForReading.readabilityHandler = readHandler
        process.terminationHandler = { process in
            stdout.fileHandleForReading.readabilityHandler = nil
            stderr.fileHandleForReading.readabilityHandler = nil
            terminationHandler(process.terminationStatus)
        }

        try process.run()
        return FFmpegRunningProcess(process: process, stdinPipe: stdin)
    }
}
