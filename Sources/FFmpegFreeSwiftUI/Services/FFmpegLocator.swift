import Foundation

public enum FFmpegTool: String, CaseIterable, Sendable {
    case ffmpeg
    case ffprobe
    case ffplay
}

public enum FFmpegLocationSource: String, Sendable {
    case userOverride
    case appSibling
    case pathEnvironment
    case commonDirectory
    case fallback
}

public struct FFmpegToolLocation: Equatable, Sendable {
    public var tool: FFmpegTool
    public var path: String
    public var source: FFmpegLocationSource
    public var isExecutable: Bool
}

public struct FFmpegLocator: @unchecked Sendable {
    public var settings: AppSettings
    public var fileManager: FileManager

    public init(settings: AppSettings, fileManager: FileManager = .default) {
        self.settings = settings
        self.fileManager = fileManager
    }

    public func locate(_ tool: FFmpegTool) -> String {
        location(for: tool).path
    }

    public func location(for tool: FFmpegTool) -> FFmpegToolLocation {
        if let override = overridePath(for: tool), fileManager.isExecutableFile(atPath: override) {
            return FFmpegToolLocation(tool: tool, path: override, source: .userOverride, isExecutable: true)
        }

        for candidate in appSiblingCandidates(for: tool.rawValue) {
            if fileManager.isExecutableFile(atPath: candidate) {
                return FFmpegToolLocation(tool: tool, path: candidate, source: .appSibling, isExecutable: true)
            }
        }

        for candidate in pathCandidates(for: tool.rawValue) {
            if fileManager.isExecutableFile(atPath: candidate) {
                return FFmpegToolLocation(tool: tool, path: candidate, source: .pathEnvironment, isExecutable: true)
            }
        }

        for candidate in commonCandidates(for: tool.rawValue) {
            if fileManager.isExecutableFile(atPath: candidate) {
                return FFmpegToolLocation(tool: tool, path: candidate, source: .commonDirectory, isExecutable: true)
            }
        }

        return FFmpegToolLocation(tool: tool, path: tool.rawValue, source: .fallback, isExecutable: false)
    }

    public func locations() -> [FFmpegToolLocation] {
        FFmpegTool.allCases.map(location(for:))
    }

    public func bestSiblingPath(for tool: FFmpegTool, basedOn path: String) -> String {
        path.replacingLastPathComponent(with: tool.rawValue)
    }

    private func appSiblingCandidates(for executable: String) -> [String] {
        let bundleDirectory = Bundle.main.bundleURL.deletingLastPathComponent()
        return [
            bundleDirectory.appendingPathComponent(executable).path,
            bundleDirectory.appendingPathComponent("\(executable).app").path,
            bundleDirectory.appendingPathComponent("bin").appendingPathComponent(executable).path,
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources").appendingPathComponent(executable).path,
            Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS").appendingPathComponent(executable).path
        ]
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
        let fallbackPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/local/bin"
        let pathValue = ProcessInfo.processInfo.environment["PATH"].flatMap(\.nonEmpty) ?? fallbackPath
        return pathValue.split(separator: ":").map { URL(fileURLWithPath: String($0)).appendingPathComponent(executable).path }
    }

    private func commonCandidates(for executable: String) -> [String] {
        [
            "/opt/homebrew/bin/\(executable)",
            "/usr/local/bin/\(executable)",
            "/opt/local/bin/\(executable)",
            "/usr/bin/\(executable)",
            "/bin/\(executable)"
        ]
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
