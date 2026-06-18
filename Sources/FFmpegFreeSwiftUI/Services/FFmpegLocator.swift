import Foundation

public enum FFmpegTool: String, CaseIterable, Sendable {
    case ffmpeg
    case ffprobe
    case ffplay
}

public struct FFmpegLocator: @unchecked Sendable {
    public var settings: AppSettings
    public var fileManager: FileManager

    public init(settings: AppSettings, fileManager: FileManager = .default) {
        self.settings = settings
        self.fileManager = fileManager
    }

    public func locate(_ tool: FFmpegTool) -> String {
        if let override = overridePath(for: tool), fileManager.isExecutableFile(atPath: override) {
            return override
        }

        let bundleSibling = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(tool.rawValue).path
        if fileManager.isExecutableFile(atPath: bundleSibling) {
            return bundleSibling
        }

        for candidate in pathCandidates(for: tool.rawValue) {
            if fileManager.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        return tool.rawValue
    }

    private func overridePath(for tool: FFmpegTool) -> String? {
        switch tool {
        case .ffmpeg:
            return settings.ffmpegExecutableOverride.nonEmpty
        case .ffprobe:
            return settings.ffprobeExecutableOverride.nonEmpty ?? settings.ffmpegExecutableOverride.replacingLastPathComponent(with: "ffprobe").nonEmpty
        case .ffplay:
            return settings.ffplayExecutableOverride.nonEmpty ?? settings.ffmpegExecutableOverride.replacingLastPathComponent(with: "ffplay").nonEmpty
        }
    }

    private func pathCandidates(for executable: String) -> [String] {
        let pathValue = ProcessInfo.processInfo.environment["PATH"] ?? "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        return pathValue.split(separator: ":").map { String($0) + "/" + executable }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    func replacingLastPathComponent(with component: String) -> String {
        guard !isEmpty else { return "" }
        return (self as NSString).deletingLastPathComponent + "/" + component
    }
}
