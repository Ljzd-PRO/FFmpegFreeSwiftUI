import Foundation

public enum AppAppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    public static func normalize(_ value: String) -> AppAppearanceMode {
        AppAppearanceMode(rawValue: value) ?? .system
    }
}

public enum AppInterfaceDensity: String, CaseIterable, Identifiable, Sendable {
    case compact
    case regular
    case spacious

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .compact: return "紧凑"
        case .regular: return "标准"
        case .spacious: return "宽松"
        }
    }

    public static func normalize(_ value: String) -> AppInterfaceDensity {
        AppInterfaceDensity(rawValue: value) ?? .regular
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var fontName: String
    public var language: String
    public var appearanceMode: String
    public var interfaceDensity: String
    public var baseFontSize: Double
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
        appearanceMode = AppAppearanceMode.system.rawValue
        interfaceDensity = AppInterfaceDensity.regular.rawValue
        baseFontSize = 13
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
        appearanceMode = AppAppearanceMode.normalize(container.decodeDefault(String.self, forKey: .appearanceMode, default: appearanceMode)).rawValue
        interfaceDensity = AppInterfaceDensity.normalize(container.decodeDefault(String.self, forKey: .interfaceDensity, default: interfaceDensity)).rawValue
        baseFontSize = container.decodeDefault(Double.self, forKey: .baseFontSize, default: baseFontSize)
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
