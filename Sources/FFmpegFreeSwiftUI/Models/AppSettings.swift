import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var fontName: String
    public var language: String
    public var selectedProcessorCores: String
    public var maxConcurrentTasks: Int
    public var queueRefreshInterval: TimeInterval
    public var preventSleepMode: Int
    public var soundEnabled: Bool
    public var autoStartTasks: Bool
    public var resetParameterPanelOnStart: Bool
    public var obfuscateTaskName: Bool
    public var deleteFailedOutputPolicy: Int
    public var workingDirectory: String
    public var ffmpegExecutableOverride: String
    public var ffprobeExecutableOverride: String
    public var ffplayExecutableOverride: String
    public var argumentPassthroughTemplate: String
    public var remoteCallEnabled: Bool
    public var remotePort: String
    public var presetAutoLoadMode: Int
    public var presetAutoLoadPath: String
    public var lastPreset: PresetData

    public init() {
        fontName = "System"
        language = AppLanguage.simplifiedChinese.rawValue
        selectedProcessorCores = ""
        maxConcurrentTasks = 1
        queueRefreshInterval = 1
        preventSleepMode = 0
        soundEnabled = true
        autoStartTasks = true
        resetParameterPanelOnStart = false
        obfuscateTaskName = false
        deleteFailedOutputPolicy = 0
        workingDirectory = ""
        ffmpegExecutableOverride = ""
        ffprobeExecutableOverride = ""
        ffplayExecutableOverride = ""
        argumentPassthroughTemplate = ""
        remoteCallEnabled = false
        remotePort = "10591"
        presetAutoLoadMode = 0
        presetAutoLoadPath = ""
        lastPreset = PresetData()
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontName = container.decodeDefault(String.self, forKey: .fontName, default: fontName)
        language = AppLanguage.normalize(container.decodeDefault(String.self, forKey: .language, default: language)).rawValue
        selectedProcessorCores = container.decodeDefault(String.self, forKey: .selectedProcessorCores, default: selectedProcessorCores)
        maxConcurrentTasks = container.decodeDefault(Int.self, forKey: .maxConcurrentTasks, default: maxConcurrentTasks)
        queueRefreshInterval = container.decodeDefault(TimeInterval.self, forKey: .queueRefreshInterval, default: queueRefreshInterval)
        preventSleepMode = container.decodeDefault(Int.self, forKey: .preventSleepMode, default: preventSleepMode)
        soundEnabled = container.decodeDefault(Bool.self, forKey: .soundEnabled, default: soundEnabled)
        autoStartTasks = container.decodeDefault(Bool.self, forKey: .autoStartTasks, default: autoStartTasks)
        resetParameterPanelOnStart = container.decodeDefault(Bool.self, forKey: .resetParameterPanelOnStart, default: resetParameterPanelOnStart)
        obfuscateTaskName = container.decodeDefault(Bool.self, forKey: .obfuscateTaskName, default: obfuscateTaskName)
        deleteFailedOutputPolicy = container.decodeDefault(Int.self, forKey: .deleteFailedOutputPolicy, default: deleteFailedOutputPolicy)
        workingDirectory = container.decodeDefault(String.self, forKey: .workingDirectory, default: workingDirectory)
        ffmpegExecutableOverride = container.decodeDefault(String.self, forKey: .ffmpegExecutableOverride, default: ffmpegExecutableOverride)
        ffprobeExecutableOverride = container.decodeDefault(String.self, forKey: .ffprobeExecutableOverride, default: ffprobeExecutableOverride)
        ffplayExecutableOverride = container.decodeDefault(String.self, forKey: .ffplayExecutableOverride, default: ffplayExecutableOverride)
        argumentPassthroughTemplate = container.decodeDefault(String.self, forKey: .argumentPassthroughTemplate, default: argumentPassthroughTemplate)
        remoteCallEnabled = container.decodeDefault(Bool.self, forKey: .remoteCallEnabled, default: remoteCallEnabled)
        remotePort = container.decodeDefault(String.self, forKey: .remotePort, default: remotePort)
        presetAutoLoadMode = container.decodeDefault(Int.self, forKey: .presetAutoLoadMode, default: presetAutoLoadMode)
        presetAutoLoadPath = container.decodeDefault(String.self, forKey: .presetAutoLoadPath, default: presetAutoLoadPath)
        lastPreset = container.decodeDefault(PresetData.self, forKey: .lastPreset, default: lastPreset)
    }
}

private extension KeyedDecodingContainer {
    func decodeDefault<T: Decodable>(_ type: T.Type, forKey key: Key, default defaultValue: T) -> T {
        (try? decodeIfPresent(type, forKey: key)) ?? defaultValue
    }
}
