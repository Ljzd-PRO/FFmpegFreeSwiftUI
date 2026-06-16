import SwiftUI
import UniformTypeIdentifiers

public struct FFplayView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @State private var filePath = ""
    @State private var message = "选择文件后会调用外部 ffplay 独立窗口。"

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("媒体文件路径", text: $filePath)
                    .textFieldStyle(.roundedBorder)
                Button("选择文件") { openFile() }
                Button("播放") { play() }
                    .disabled(filePath.isEmpty)
            }
            .buttonStyle(.bordered)
            Text(message)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
    }

    private func play() {
        do {
            let service = FFprobeService(locator: FFmpegLocator(settings: settingsStore.settings), settings: settingsStore.settings)
            try service.play(file: filePath)
            message = "已启动 ffplay"
        } catch {
            message = "启动失败: \(error.localizedDescription)"
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            filePath = url.path
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    filePath = url.path
                    play()
                }
            }
        }
        return true
    }
}
