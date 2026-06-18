import SwiftUI

public struct MuxingView: View {
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var inputs: [MuxingInput] = []
    @State private var selectedID: MuxingInput.ID?
    @State private var output = ""
    @State private var statusMessage = ""
    private let builder = MuxingCommandBuilder()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ToolBanner(text: "仅提供最基础的混流，高级功能请移步 MKVToolNix GUI；分离请用 MKVExtract GUI")

            HStack {
                Button("添加文件") { ToolFilePanels.openFiles(addFiles) }
                Button("上移") { moveSelection(offset: -1) }.disabled(selectedID == nil)
                Button("下移") { moveSelection(offset: 1) }.disabled(selectedID == nil)
                Button("移除") { removeSelection() }.disabled(selectedID == nil)
                Spacer()
                if !statusMessage.isEmpty {
                    StatusPill(text: statusMessage, color: .green)
                }
            }
            .buttonStyle(.bordered)

            Table(inputs, selection: $selectedID) {
                TableColumn("文件") { input in
                    Text(input.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                TableColumn("视频流") { input in Text(input.videoStreams.isEmpty ? "-" : input.videoStreams) }
                    .width(80)
                TableColumn("音频流") { input in Text(input.audioStreams.isEmpty ? "-" : input.audioStreams) }
                    .width(80)
                TableColumn("字幕流") { input in Text(input.subtitleStreams.isEmpty ? "-" : input.subtitleStreams) }
                    .width(80)
                TableColumn("章节") { input in Text(input.usesChapters ? "使用此" : "-") }
                    .width(70)
                TableColumn("元数据") { input in Text(input.usesMetadata ? "使用此" : "-") }
                    .width(80)
            }
            .frame(minHeight: 260)
            .acceptsFileDrops(addFiles)
            .onDeleteCommand { removeSelection() }

            GroupBox("选中项流控制") {
                if let binding = selectedInputBinding {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            streamField("视频流索引号", text: binding.videoStreams)
                            streamField("音频流索引号", text: binding.audioStreams)
                            streamField("字幕流索引号", text: binding.subtitleStreams)
                        }
                        HStack {
                            Toggle("使用此文件的章节", isOn: Binding(
                                get: { binding.wrappedValue.usesChapters },
                                set: { setChapters(binding.wrappedValue.id, enabled: $0) }
                            ))
                            Toggle("使用此文件的元数据", isOn: Binding(
                                get: { binding.wrappedValue.usesMetadata },
                                set: { setMetadata(binding.wrappedValue.id, enabled: $0) }
                            ))
                            Spacer()
                        }
                    }
                    .padding(8)
                } else {
                    Text("添加输入文件，然后选中来编辑要使用哪些流，使用键盘 F3 和 F4 来排序，Delete 来移除")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
            }

            HStack {
                TextField("输出到目标位置", text: $output)
                    .textFieldStyle(.roundedBorder)
                Button("选择位置") { ToolFilePanels.saveFile { output = $0 } }
                Button("启动混流") { addTask() }
                    .disabled(inputs.isEmpty || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [.command])
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onMoveCommand { direction in
            if direction == .up { moveSelection(offset: -1) }
            if direction == .down { moveSelection(offset: 1) }
        }
    }

    private var selectedInputBinding: Binding<MuxingInput>? {
        guard let selectedID, let index = inputs.firstIndex(where: { $0.id == selectedID }) else { return nil }
        return $inputs[index]
    }

    private func streamField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("多个流用英文逗号隔开", text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func addFiles(_ paths: [String]) {
        for path in paths where !inputs.contains(where: { $0.path == path }) {
            inputs.append(MuxingInput(path: path))
        }
        selectedID = inputs.last?.id
        statusMessage = paths.isEmpty ? "" : "已添加 \(paths.count) 个文件"
    }

    private func moveSelection(offset: Int) {
        guard let selectedID, let index = inputs.firstIndex(where: { $0.id == selectedID }) else { return }
        let next = index + offset
        guard inputs.indices.contains(next) else { return }
        inputs.swapAt(index, next)
    }

    private func removeSelection() {
        guard let selectedID else { return }
        inputs.removeAll { $0.id == selectedID }
        self.selectedID = inputs.first?.id
    }

    private func setChapters(_ id: UUID, enabled: Bool) {
        for index in inputs.indices {
            inputs[index].usesChapters = enabled && inputs[index].id == id
        }
    }

    private func setMetadata(_ id: UUID, enabled: Bool) {
        for index in inputs.indices {
            inputs[index].usesMetadata = enabled && inputs[index].id == id
        }
    }

    private func addTask() {
        let args = builder.build(inputs: inputs, output: output)
        queueStore.addCommandTask(arguments: args, displayName: "混流任务", outputPath: output, inputPath: inputs.first?.path ?? "")
        statusMessage = "已加入编码队列"
    }
}
