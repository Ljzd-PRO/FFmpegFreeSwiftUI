import SwiftUI
import UniformTypeIdentifiers

public struct EncodeQueueView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var presetStore: PresetStore
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var messageToSend = ""
    @State private var showingErrors = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            Table(queueStore.tasks, selection: $queueStore.selectedTaskID) {
                TableColumn("文件") { task in
                    Text(task.displayName)
                        .lineLimit(1)
                }
                TableColumn("状态") { task in
                    StatusCell(task: task)
                }
                TableColumn("进度") { task in
                    ProgressCell(task: task)
                }
                TableColumn("效率") { task in
                    Text(task.progress.speed == "N/A" ? "N/A" : speedPercent(task.progress.speed))
                }
                TableColumn("输出大小 && 预估") { task in
                    Text(task.progress.outputSizeText + task.progress.estimatedSizeText)
                        .lineLimit(1)
                }
                TableColumn("质量") { task in
                    Text(task.progress.quality)
                }
                TableColumn("比特率") { task in
                    Text(task.progress.bitrate)
                }
                TableColumn("预计剩余 && 已用") { task in
                    Text("\(task.progress.remainingText) - \(task.progress.elapsedText)")
                        .lineLimit(1)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
            Divider()
            bottomPanel
        }
        .sheet(isPresented: $showingErrors) {
            ErrorListView(task: queueStore.selectedTask)
                .frame(minWidth: 640, minHeight: 420)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                appState.presentOpenPanelForQueue()
            } label: {
                Label("添加文件", systemImage: "plus")
            }
            Button {
                queueStore.startSelected()
            } label: {
                Label("开始", systemImage: "play.fill")
            }
            Button {
                queueStore.pauseSelected()
            } label: {
                Label("暂停", systemImage: "pause.fill")
            }
            Button {
                queueStore.resumeSelected()
            } label: {
                Label("恢复", systemImage: "playpause.fill")
            }
            Button(role: .destructive) {
                queueStore.stopSelected()
            } label: {
                Label("停止", systemImage: "stop.fill")
            }
            Button(role: .destructive) {
                queueStore.removeSelected()
            } label: {
                Label("移除", systemImage: "trash")
            }
            Button {
                queueStore.resetSelected()
            } label: {
                Label("重置", systemImage: "arrow.counterclockwise")
            }
            Button {
                queueStore.revealSelectedOutput()
            } label: {
                Label("定位", systemImage: "folder")
            }
            Menu {
                Button("复制任务命令行") { queueStore.copySelectedCommandLine() }
                Button("参数面板覆盖到任务") { queueStore.overwriteSelectedTaskPreset(with: presetStore.current) }
                Button("任务参数覆盖到参数面板") {
                    if let task = queueStore.selectedTask {
                        presetStore.loadFromTask(task)
                    }
                }
                Button("捕获错误") { showingErrors = true }
            } label: {
                Label("任务管理菜单", systemImage: "ellipsis.circle")
            }
            Spacer()
        }
        .buttonStyle(.bordered)
        .padding(10)
    }

    private var bottomPanel: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("向 ffmpeg 发送 stdin 消息", text: $messageToSend)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(sendMessage)
                Button("发送", action: sendMessage)
                Button("捕获 \(queueStore.selectedTask?.errors.count ?? 0) 个错误") {
                    showingErrors = true
                }
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("实时输出")
                        .font(.caption.weight(.semibold))
                    Text(queueStore.selectedTask?.realtimeOutput ?? "")
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("命令行")
                        .font(.caption.weight(.semibold))
                    Text(commandPreview)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(10)
        .frame(minHeight: 130)
    }

    private var commandPreview: String {
        guard let task = queueStore.selectedTask else { return "" }
        return task.commandLine.isEmpty ? "任务开始时生成命令行" : "ffmpeg " + task.commandLine
    }

    private func sendMessage() {
        guard !messageToSend.isEmpty else { return }
        queueStore.sendMessageToSelected(messageToSend)
        messageToSend = ""
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var paths: [String] = []
        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    paths.append(url.path)
                } else if let url = item as? URL {
                    paths.append(url.path)
                }
            }
        }
        group.notify(queue: .main) {
            queueStore.addFiles(paths, preset: presetStore.current)
        }
        return true
    }

    private func color(for status: EncodingStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .running: return .green
        case .paused: return .orange
        case .completed: return .mint
        case .stopped, .failed: return .red
        }
    }

    private func speedPercent(_ speed: String) -> String {
        let value = speed.replacingOccurrences(of: "x", with: "")
        guard let double = Double(value) else { return speed }
        return String(format: "%.0f%%", double * 100)
    }
}

private struct StatusCell: View {
    @ObservedObject var task: EncodingTask

    var body: some View {
        Text(task.status.rawValue)
            .foregroundStyle(color(for: task.status))
    }

    private func color(for status: EncodingStatus) -> Color {
        switch status {
        case .pending: return .secondary
        case .running: return .green
        case .paused: return .orange
        case .completed: return .mint
        case .stopped, .failed: return .red
        }
    }
}

private struct ProgressCell: View {
    @ObservedObject var task: EncodingTask

    var body: some View {
        HStack {
            ProgressView(value: task.progress.percent)
                .frame(width: 70)
            Text(task.progress.percent > 0 ? String(format: "%.1f%%", task.progress.percent * 100) : "N/A")
        }
    }
}

private struct ErrorListView: View {
    var task: EncodingTask?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(task?.displayName ?? "未选择任务")
                .font(.headline)
            ScrollView {
                Text((task?.errors ?? []).joined(separator: "\n"))
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
