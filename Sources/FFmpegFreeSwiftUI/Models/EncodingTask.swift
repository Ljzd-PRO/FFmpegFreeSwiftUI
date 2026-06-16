import Foundation

public enum EncodingStatus: String, Codable, CaseIterable, Sendable {
    case pending = "未处理"
    case running = "正在处理"
    case paused = "已暂停"
    case completed = "已完成"
    case stopped = "已停止"
    case failed = "错误"
}

public struct EncodingProgress: Codable, Equatable, Sendable {
    public var frame: String = ""
    public var fps: String = ""
    public var quality: String = "N/A"
    public var outputSizeKB: Int64 = 0
    public var outputSizeText: String = "N/A"
    public var currentTime: TimeInterval = 0
    public var totalTime: TimeInterval = 0
    public var bitrate: String = "N/A"
    public var speed: String = "N/A"
    public var percent: Double = 0
    public var estimatedSizeText: String = ""
    public var remainingText: String = "N/A"
    public var elapsedText: String = "0s"

    public init() {}
}

public final class EncodingTask: ObservableObject, Identifiable {
    public let id: UUID
    @Published public var preset: PresetData?
    @Published public var inputFile: String
    @Published public var outputFile: String
    @Published public var displayName: String
    @Published public var commandLine: String
    @Published public var status: EncodingStatus
    @Published public var progress: EncodingProgress
    @Published public var realtimeOutput: String
    @Published public var errors: [String]
    @Published public var nonProgressOutput: [String]
    @Published public var startedAt: Date?
    @Published public var completedAt: Date?

    public var processIdentifier: Int32?
    public var wasManuallyStopped = false

    public init(
        id: UUID = UUID(),
        preset: PresetData? = nil,
        inputFile: String = "",
        outputFile: String = "",
        displayName: String,
        commandLine: String = "",
        status: EncodingStatus = .pending
    ) {
        self.id = id
        self.preset = preset
        self.inputFile = inputFile
        self.outputFile = outputFile
        self.displayName = displayName
        self.commandLine = commandLine
        self.status = status
        self.progress = EncodingProgress()
        self.realtimeOutput = ""
        self.errors = []
        self.nonProgressOutput = []
        self.startedAt = nil
        self.completedAt = nil
    }
}
