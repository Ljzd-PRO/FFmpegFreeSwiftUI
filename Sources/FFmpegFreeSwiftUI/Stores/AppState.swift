import AppKit
import Foundation

@MainActor
public final class AppState: ObservableObject {
    public let settingsStore: SettingsStore
    public let presetStore: PresetStore
    public let queueStore: EncodingQueueStore
    public let qualityStore: QualityAssessmentStore
    public let remoteServer: RemoteCommandServer
    @Published public var selectedSection: MainSection? = .start

    public init() {
        let settings = SettingsStore()
        let preset = PresetStore(settingsStore: settings)
        let queue = EncodingQueueStore(settingsStore: settings)
        let quality = QualityAssessmentStore(settingsStore: settings)
        settingsStore = settings
        presetStore = preset
        queueStore = queue
        qualityStore = quality
        remoteServer = RemoteCommandServer(queueStore: queue)
        remoteServer.update(enabled: settings.settings.remoteCallEnabled, port: settings.settings.remotePort)
        quality.refreshFilterAvailability()
    }

    public func navigate(to section: MainSection) {
        selectedSection = section
    }

    public func presentOpenPanelForQueue() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            let paths = panel.urls.map(\.path)
            Task { @MainActor in
                self?.queueStore.addFiles(paths, preset: self?.presetStore.current ?? PresetData())
            }
        }
    }

    public func presentPresetImportPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = []
        panel.canChooseFiles = true
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                self?.presetStore.importPreset(from: url)
            }
        }
    }

    public func presentPresetExportPanel() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Preset.3fui"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                self?.presetStore.exportPreset(to: url)
            }
        }
    }
}
