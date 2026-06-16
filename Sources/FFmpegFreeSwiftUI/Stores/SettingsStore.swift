import Foundation

@MainActor
public final class SettingsStore: ObservableObject {
    @Published public var settings: AppSettings {
        didSet {
            scheduleSave()
        }
    }

    public let url: URL
    private var saveTask: Task<Void, Never>?

    public init(url: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = base.appendingPathComponent("FFmpegFreeSwiftUI", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = url ?? directory.appendingPathComponent("Settings.json")
        if let data = try? Data(contentsOf: self.url),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    public func save() {
        saveTask?.cancel()
        saveTask = nil
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(settings)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Settings save failures are surfaced in UI by explicit actions; autosave stays quiet.
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = settings
        let url = url
        saveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 450_000_000)
                try Task.checkCancellation()
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                let data = try encoder.encode(snapshot)
                try data.write(to: url, options: [.atomic])
            } catch {
                // Autosave remains quiet; explicit saves call save().
            }
        }
    }

    deinit {
        saveTask?.cancel()
    }
}
