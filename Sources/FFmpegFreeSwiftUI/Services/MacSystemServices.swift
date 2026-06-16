import AppKit
import Foundation

public enum MacSystemServices {
    public static func revealInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public static func trashItem(path: String) throws {
        let url = URL(fileURLWithPath: path)
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
    }

    public static func copyToPasteboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    public static func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    public static func preserveDates(from input: String, to output: String, preset: PresetData) {
        guard FileManager.default.fileExists(atPath: input),
              FileManager.default.fileExists(atPath: output) else {
            return
        }
        let inputURL = URL(fileURLWithPath: input)
        let outputURL = URL(fileURLWithPath: output)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: inputURL.path) else {
            return
        }
        var newAttributes: [FileAttributeKey: Any] = [:]
        if preset.preserveModificationDate, let date = attributes[.modificationDate] {
            newAttributes[.modificationDate] = date
        }
        if preset.preserveCreationDate, let date = attributes[.creationDate] {
            newAttributes[.creationDate] = date
        }
        if !newAttributes.isEmpty {
            try? FileManager.default.setAttributes(newAttributes, ofItemAtPath: outputURL.path)
        }
    }
}

public final class SleepPreventer {
    private var process: Process?

    public init() {}

    public func start(reason: String = "FFmpegFreeSwiftUI encoding task") {
        guard process == nil else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-dimsu"]
        do {
            try process.run()
            self.process = process
        } catch {
            self.process = nil
        }
    }

    public func stop() {
        guard let process else { return }
        if process.isRunning {
            process.terminate()
        }
        self.process = nil
    }

    deinit {
        stop()
    }
}
