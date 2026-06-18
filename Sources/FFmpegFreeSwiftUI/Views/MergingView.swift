import SwiftUI

public struct MergingView: View {
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var files: [String] = []
    @State private var selection = Set<String>()
    @State private var output = ""
    @State private var statusMessage = ""
    private let builder = MergingCommandBuilder()

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ToolBanner(text: "仅提供最基础的合并，仅复制流，要求多个参数一致；高级需求请直接用剪辑软件")

            HStack {
                Button("添加文件") { ToolFilePanels.openFiles(addFiles) }
                Button("上移") { moveSelection(offset: -1) }.disabled(selection.isEmpty)
                Button("下移") { moveSelection(offset: 1) }.disabled(selection.isEmpty)
                Button("移除") { removeSelection() }.disabled(selection.isEmpty)
                Spacer()
                Text("使用键盘 F3 和 F4 来排序，Delete 来移除")
                    .foregroundStyle(.secondary)
                if !statusMessage.isEmpty {
                    StatusPill(text: statusMessage, color: .green)
                }
            }
            .buttonStyle(.bordered)

            List(selection: $selection) {
                ForEach(files, id: \.self) { path in
                    Text(path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(minHeight: 360)
            .acceptsFileDrops(addFiles)
            .onDeleteCommand { removeSelection() }
            .onMoveCommand { direction in
                if direction == .up { moveSelection(offset: -1) }
                if direction == .down { moveSelection(offset: 1) }
            }

            HStack {
                TextField("输出到目标位置", text: $output)
                    .textFieldStyle(.roundedBorder)
                Button("选择位置") { ToolFilePanels.saveFile { output = $0 } }
                Button("启动合并") { addTask() }
                    .disabled(files.isEmpty || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [.command])
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func addFiles(_ paths: [String]) {
        for path in paths where !files.contains(path) {
            files.append(path)
        }
        statusMessage = paths.isEmpty ? "" : "已添加 \(paths.count) 个文件"
    }

    private func moveSelection(offset: Int) {
        let selectedIndexes = selection.compactMap { selected in files.firstIndex(of: selected) }.sorted()
        guard !selectedIndexes.isEmpty else { return }
        let movingIndexes = offset < 0 ? selectedIndexes : selectedIndexes.reversed()
        for index in movingIndexes {
            let next = index + offset
            guard files.indices.contains(next), !selectedIndexes.contains(next) else { continue }
            files.swapAt(index, next)
        }
    }

    private func removeSelection() {
        files.removeAll { selection.contains($0) }
        selection.removeAll()
    }

    private func addTask() {
        do {
            let concat = try builder.writeConcatFile(files: files)
            let args = builder.build(concatFile: concat.path, output: output)
            queueStore.addCommandTask(arguments: args, displayName: "合并任务", outputPath: output)
            statusMessage = "已加入编码队列"
        } catch {
            statusMessage = "创建合并列表失败"
        }
    }
}
