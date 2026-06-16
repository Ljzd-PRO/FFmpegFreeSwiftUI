import SwiftUI
import UniformTypeIdentifiers

public struct MediaInfoView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @State private var filePath = ""
    @State private var output = ""
    @State private var isRunning = false

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("媒体文件路径", text: $filePath)
                    .textFieldStyle(.roundedBorder)
                Button("选择文件") { openFile() }
                Button("调用 ffprobe") { runProbe() }
                    .disabled(filePath.isEmpty || isRunning)
                Button("复制输出") { MacSystemServices.copyToPasteboard(output) }
            }
            .buttonStyle(.bordered)
            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        }
        .padding()
    }

    private func runProbe() {
        isRunning = true
        output = "正在调用 ffprobe..."
        let settings = settingsStore.settings
        Task {
            do {
                let text = try await FFprobeService(locator: FFmpegLocator(settings: settings), settings: settings).probe(file: filePath)
                await MainActor.run {
                    output = text
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    output = error.localizedDescription
                    isRunning = false
                }
            }
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            filePath = url.path
            runProbe()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    filePath = url.path
                    runProbe()
                }
            }
        }
        return true
    }
}
