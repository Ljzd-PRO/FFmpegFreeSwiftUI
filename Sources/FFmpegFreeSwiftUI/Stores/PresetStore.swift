import Foundation

@MainActor
public final class PresetStore: ObservableObject {
    @Published public var current: PresetData
    @Published public var lastMessage: String = ""

    private let settingsStore: SettingsStore

    public init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        current = settingsStore.settings.lastPreset
    }

    public func reset() {
        current = PresetData()
        persistAsLastPreset()
    }

    public func importPreset(from url: URL) {
        do {
            current = try PresetIOService.load(from: url)
            persistAsLastPreset()
            lastMessage = "已导入预设: \(url.lastPathComponent)"
        } catch {
            lastMessage = "导入失败: \(error.localizedDescription)"
        }
    }

    public func exportPreset(to url: URL) {
        do {
            try PresetIOService.save(current, to: url)
            lastMessage = "已导出预设: \(url.lastPathComponent)"
        } catch {
            lastMessage = "导出失败: \(error.localizedDescription)"
        }
    }

    public func loadFromTask(_ task: EncodingTask) {
        guard let preset = task.preset else {
            lastMessage = "该任务没有预设快照"
            return
        }
        current = preset
        persistAsLastPreset()
        lastMessage = "已从任务反写参数面板"
    }

    public func persistAsLastPreset() {
        settingsStore.settings.lastPreset = current
    }
}
