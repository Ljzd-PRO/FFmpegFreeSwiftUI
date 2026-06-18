import Foundation

public enum QualityMetric: String, Codable, CaseIterable, Identifiable, Sendable {
    case psnr = "PSNR"
    case xpsnr = "XPSNR"
    case ssim = "SSIM"
    case vmaf = "VMAF"

    public var id: String { rawValue }

    public var filterName: String {
        switch self {
        case .psnr: return "psnr"
        case .xpsnr: return "xpsnr"
        case .ssim: return "ssim"
        case .vmaf: return "libvmaf"
        }
    }
}

public enum QualityAssessmentStatus: String, Codable, Sendable {
    case pending = "等待中"
    case running = "评测中"
    case completed = "已完成"
    case stopped = "已停止"
    case failed = "错误"
}

public struct QualityAssessmentConfiguration: Codable, Equatable, Sendable {
    public var startTime: String
    public var duration: String
    public var outputDirectory: String
    public var vmafModel: String
    public var vmafPool: String
    public var sampleInterval: String

    public init(
        startTime: String = "",
        duration: String = "",
        outputDirectory: String = "",
        vmafModel: String = "",
        vmafPool: String = "",
        sampleInterval: String = ""
    ) {
        self.startTime = startTime
        self.duration = duration
        self.outputDirectory = outputDirectory
        self.vmafModel = vmafModel
        self.vmafPool = vmafPool
        self.sampleInterval = sampleInterval
    }
}

public struct QualityAssessmentResult: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var referenceFile: String
    public var distortedFile: String
    public var metric: QualityMetric
    public var score: String
    public var average: String
    public var minimum: String
    public var logPath: String
    public var elapsedSeconds: TimeInterval
    public var completedAt: Date
    public var rawSummary: String

    public init(
        id: UUID = UUID(),
        referenceFile: String,
        distortedFile: String,
        metric: QualityMetric,
        score: String = "N/A",
        average: String = "N/A",
        minimum: String = "N/A",
        logPath: String = "",
        elapsedSeconds: TimeInterval = 0,
        completedAt: Date = Date(),
        rawSummary: String = ""
    ) {
        self.id = id
        self.referenceFile = referenceFile
        self.distortedFile = distortedFile
        self.metric = metric
        self.score = score
        self.average = average
        self.minimum = minimum
        self.logPath = logPath
        self.elapsedSeconds = elapsedSeconds
        self.completedAt = completedAt
        self.rawSummary = rawSummary
    }
}

@MainActor
public final class QualityAssessmentTask: ObservableObject, Identifiable {
    public let id: UUID
    @Published public var referenceFile: String
    @Published public var distortedFile: String
    @Published public var metrics: [QualityMetric]
    @Published public var configuration: QualityAssessmentConfiguration
    @Published public var status: QualityAssessmentStatus
    @Published public var currentMetric: QualityMetric?
    @Published public var realtimeOutput: String
    @Published public var results: [QualityAssessmentResult]
    @Published public var errors: [String]
    @Published public var startedAt: Date?
    @Published public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        referenceFile: String,
        distortedFile: String,
        metrics: [QualityMetric],
        configuration: QualityAssessmentConfiguration,
        status: QualityAssessmentStatus = .pending
    ) {
        self.id = id
        self.referenceFile = referenceFile
        self.distortedFile = distortedFile
        self.metrics = metrics
        self.configuration = configuration
        self.status = status
        self.currentMetric = nil
        self.realtimeOutput = ""
        self.results = []
        self.errors = []
        self.startedAt = nil
        self.completedAt = nil
    }
}
