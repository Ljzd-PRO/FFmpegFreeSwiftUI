import SwiftUI
import UniformTypeIdentifiers

public struct PrepareFilesView: View {
    @EnvironmentObject private var presetStore: PresetStore
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var files: [String] = []
    @State private var customOutputDirectory = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    openFiles()
                } label: {
                    Label("添加文件", systemImage: "plus")
                }
                Button {
                    openDirectory()
                } label: {
                    Label("输出目录", systemImage: "folder")
                }
                TextField("自定义输出目录（留空则跟随预设或输入目录）", text: $customOutputDirectory)
                    .textFieldStyle(.roundedBorder)
                Button {
                    queueStore.addFiles(files, preset: presetStore.current, customOutputDirectory: customOutputDirectory)
                    files.removeAll()
                } label: {
                    Label("加入编码队列", systemImage: "tray.and.arrow.down")
                }
                .disabled(files.isEmpty)
            }
            .buttonStyle(.bordered)

            List(files, id: \.self) { path in
                HStack {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                    Spacer()
                    Text(path)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        }
        .padding()
    }

    private func openFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK else { return }
            files.append(contentsOf: panel.urls.map(\.path))
        }
    }

    private func openDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            customOutputDirectory = url.path
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async { files.append(url.path) }
                }
            }
        }
        return true
    }
}
