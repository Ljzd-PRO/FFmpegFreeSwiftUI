import Foundation
import FFmpegFreeSwiftUI

public enum TestMode: String {
    case commandOnly = "command-only"
    case withFFmpeg = "with-ffmpeg"
    case all
}

public struct TestConfiguration {
    public static let modeEnvironmentKey = "FFMPEGFREE_TEST_MODE"
    public static let ffmpegPathEnvironmentKey = "FFMPEGFREE_FFMPEG_PATH"
    public static let legacyFFmpegPathEnvironmentKey = "FFMPEG_PATH"
    public static let requireFFmpegEnvironmentKey = "FFMPEGFREE_REQUIRE_FFMPEG"
    public static let keepTempEnvironmentKey = "FFMPEGFREE_KEEP_TEMP"

    public var mode: TestMode = .commandOnly
    public var ffmpegPath: String?
    public var requireFFmpeg = false
    public var keepTemp = false
    public var listOnly = false

    public init(
        mode: TestMode = .commandOnly,
        ffmpegPath: String? = nil,
        requireFFmpeg: Bool = false,
        keepTemp: Bool = false,
        listOnly: Bool = false
    ) {
        self.mode = mode
        self.ffmpegPath = ffmpegPath
        self.requireFFmpeg = requireFFmpeg
        self.keepTemp = keepTemp
        self.listOnly = listOnly
    }

    public static func environmentDefaults(
        defaultMode: TestMode = .commandOnly,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> TestConfiguration {
        var config = TestConfiguration(mode: defaultMode)
        if let modeValue = cleanEnvironmentValue(environment[modeEnvironmentKey]) {
            guard let mode = TestMode(rawValue: modeValue) else {
                throw TestFailure("Expected \(modeEnvironmentKey)=command-only|with-ffmpeg|all")
            }
            config.mode = mode
        }
        if let path = cleanEnvironmentValue(environment[ffmpegPathEnvironmentKey])
            ?? cleanEnvironmentValue(environment[legacyFFmpegPathEnvironmentKey]) {
            config.ffmpegPath = path
        }
        if let require = cleanEnvironmentValue(environment[requireFFmpegEnvironmentKey]) {
            config.requireFFmpeg = boolEnvironmentValue(require)
        }
        if let keepTemp = cleanEnvironmentValue(environment[keepTempEnvironmentKey]) {
            config.keepTemp = boolEnvironmentValue(keepTemp)
        }
        return config
    }

    public static func parse(
        arguments: [String],
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> TestConfiguration {
        var config = try environmentDefaults(environment: environment)
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--mode":
                index += 1
                guard index < arguments.count, let mode = TestMode(rawValue: arguments[index]) else {
                    throw TestFailure("Expected --mode command-only|with-ffmpeg|all")
                }
                config.mode = mode
            case "--ffmpeg":
                index += 1
                guard index < arguments.count else {
                    throw TestFailure("Expected path after --ffmpeg")
                }
                config.ffmpegPath = arguments[index]
            case "--require-ffmpeg":
                config.requireFFmpeg = true
            case "--keep-temp":
                config.keepTemp = true
            case "--list":
                config.listOnly = true
            case "--help", "-h":
                printUsage()
                exit(0)
            default:
                throw TestFailure("Unknown argument: \(argument)")
            }
            index += 1
        }
        return config
    }

    public static func printUsage() {
        print("""
        Usage:
          swift run FFmpegFreeSwiftUITestRunner [--mode command-only|with-ffmpeg|all] [--ffmpeg /path/to/ffmpeg-or-directory] [--require-ffmpeg] [--keep-temp] [--list]

        Modes:
          command-only  Build commands and validate preset behavior without ffmpeg. Default.
          with-ffmpeg   Generate tiny media files and run safe ffmpeg smoke tests.
          all           Run command-only plus with-ffmpeg tests.

        Environment:
          FFMPEGFREE_TEST_MODE     command-only, with-ffmpeg, or all.
          FFMPEGFREE_FFMPEG_PATH   Full ffmpeg path or a directory that contains ffmpeg.
        """)
    }
}

public struct TestFailure: Error, CustomStringConvertible {
    public let description: String

    public init(_ description: String) {
        self.description = description
    }
}

public struct TestSkip: Error, CustomStringConvertible {
    public let description: String

    public init(_ description: String) {
        self.description = description
    }
}

public struct TestCase {
    public var name: String
    public var group: String
    public var requiresFFmpeg: Bool
    public var body: (TestContext) async throws -> Void

    public init(_ group: String, _ name: String, requiresFFmpeg: Bool = false, body: @escaping (TestContext) throws -> Void) {
        self.group = group
        self.name = name
        self.requiresFFmpeg = requiresFFmpeg
        self.body = { context in
            try body(context)
        }
    }

    public init(_ group: String, _ name: String, requiresFFmpeg: Bool = false, body: @escaping (TestContext) async throws -> Void) {
        self.group = group
        self.name = name
        self.requiresFFmpeg = requiresFFmpeg
        self.body = body
    }
}

public struct TestContext {
    public var configuration: TestConfiguration
    public var ffmpegPath: String?
    public var tempRoot: URL

    public init(configuration: TestConfiguration, ffmpegPath: String?, tempRoot: URL) {
        self.configuration = configuration
        self.ffmpegPath = ffmpegPath
        self.tempRoot = tempRoot
    }

    public var builder: FFmpegCommandBuilder {
        FFmpegCommandBuilder()
    }
}

public func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(message)
    }
}

public func expectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) throws {
    if lhs != rhs {
        throw TestFailure("\(message): \(lhs) != \(rhs)")
    }
}

public func expectContains(_ text: String, _ fragment: String, _ message: String) throws {
    try expect(text.contains(fragment), "\(message). Missing fragment: \(fragment)\nCommand: \(text)")
}

public func expectNotContains(_ text: String, _ fragment: String, _ message: String) throws {
    try expect(!text.contains(fragment), "\(message). Unexpected fragment: \(fragment)\nCommand: \(text)")
}

public func runOnMainActor<T>(_ body: @MainActor () throws -> T) async throws -> T {
    try await MainActor.run {
        try body()
    }
}

public func waitUntil(
    timeout: TimeInterval = 5,
    interval: TimeInterval = 0.05,
    _ condition: @escaping @Sendable () async throws -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if try await condition() {
            return
        }
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
    throw TestFailure("Timed out waiting for condition")
}

public func command(for preset: PresetData, input: String = "/tmp/input file.mkv", output: String = "/tmp/output file.mp4") -> String {
    FFmpegCommandBuilder().build(preset: preset, input: input, output: output)
}

public func requireCapability(_ encoder: String) throws -> VideoEncoderCapability {
    guard let capability = VideoEncoderCapabilityCatalog.defaultCapability(for: encoder) else {
        throw TestFailure("missing capability for \(encoder)")
    }
    return capability
}

public func locateFFmpeg(configuration: TestConfiguration) -> String? {
    if let explicit = configuration.ffmpegPath {
        return executablePath(from: explicit, defaultExecutableName: "ffmpeg")
    }
    let located = FFmpegLocator(settings: AppSettings()).locate(.ffmpeg)
    return FileManager.default.isExecutableFile(atPath: located) ? located : nil
}

public func isTestSelected(_ test: TestCase, mode: TestMode) -> Bool {
    switch mode {
    case .commandOnly:
        return !test.requiresFFmpeg
    case .withFFmpeg:
        return test.requiresFFmpeg
    case .all:
        return true
    }
}

public func executablePath(from value: String, defaultExecutableName: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: trimmed, isDirectory: &isDirectory), isDirectory.boolValue {
        let candidate = URL(fileURLWithPath: trimmed).appendingPathComponent(defaultExecutableName).path
        return FileManager.default.isExecutableFile(atPath: candidate) ? candidate : nil
    }

    if trimmed.contains("/") {
        return FileManager.default.isExecutableFile(atPath: trimmed) ? trimmed : nil
    }

    return executablePath(named: trimmed)
}

public func executablePath(named name: String) -> String? {
    let pathValue = ProcessInfo.processInfo.environment["PATH"] ?? "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    let directories = pathValue.split(separator: ":").map(String.init) + ["/opt/homebrew/bin", "/usr/local/bin"]
    for directory in directories {
        let path = "\(directory)/\(name)"
        if FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
    }
    return nil
}

private func cleanEnvironmentValue(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty || trimmed.hasPrefix("$(") {
        return nil
    }
    return trimmed
}

private func boolEnvironmentValue(_ value: String) -> Bool {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "1", "true", "yes", "y", "on":
        return true
    default:
        return false
    }
}

@discardableResult
public func runProcess(_ executable: String, arguments: [String], timeout: TimeInterval = 20) throws -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    let deadline = Date().addingTimeInterval(timeout)
    while process.isRunning && Date() < deadline {
        Thread.sleep(forTimeInterval: 0.05)
    }
    if process.isRunning {
        process.terminate()
        Thread.sleep(forTimeInterval: 0.2)
        if process.isRunning {
            process.interrupt()
        }
        throw TestFailure("Process timed out: \(executable) \(arguments.joined(separator: " "))")
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    return (process.terminationStatus, output)
}

public func splitCommandArguments(_ command: String, ffmpegPath: String) -> [String] {
    var arguments = ShellQuoting.splitArguments(command)
    if arguments.first == ffmpegPath || arguments.first == "ffmpeg" {
        arguments.removeFirst()
    }
    return arguments
}
