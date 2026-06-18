import SwiftUI

public struct PerformanceView: View {
    @EnvironmentObject private var queueStore: EncodingQueueStore
    @State private var snapshot = PerformanceSnapshot.empty
    @State private var history: [Double] = []
    @State private var refreshTask: Task<Void, Never>?
    private let monitor = PerformanceMonitor()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ToolBanner(text: "性能监控会在切到其他选项卡时自动暂停；当前显示 CPU、内存、磁盘和编码队列负载")
                dashboard
                cpuGrid
            }
            .padding(24)
        }
        .task { startRefreshLoop() }
        .onDisappear { stopRefreshLoop() }
    }

    private var dashboard: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                GaugeCard(title: "CPU", value: snapshot.cpuUsage, subtitle: snapshot.loadAverageText)
                GaugeCard(title: "内存", value: snapshot.memoryUsage, subtitle: snapshot.memoryText)
                GaugeCard(title: "磁盘", value: snapshot.diskUsage, subtitle: snapshot.diskText)
                StatCard(title: "编码队列", value: "\(snapshot.runningQueueTasks)/\(snapshot.pendingQueueTasks)", detail: "运行中 / 未处理")
            }
            GridRow {
                TrendCard(title: "系统概览", values: history)
                    .gridCellColumns(4)
            }
        }
    }

    private var cpuGrid: some View {
        GroupBox("CPU 逻辑核心") {
            CPUCoreBarChart(values: snapshot.coreUsages)
                .frame(height: 220)
                .padding(10)
        }
    }

    private func startRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                let running = await MainActor.run { queueStore.tasks.filter { $0.status == .running }.count }
                let pending = await MainActor.run { queueStore.tasks.filter { $0.status == .pending }.count }
                let next = await monitor.snapshot(runningQueueTasks: running, pendingQueueTasks: pending)
                await MainActor.run {
                    snapshot = next
                    history.append(next.cpuUsage)
                    if history.count > 40 {
                        history.removeFirst(history.count - 40)
                    }
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    private func stopRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}

private struct GaugeCard: View {
    var title: String
    var value: Double
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.16), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(max(value, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(value * 100))%")
                    .font(.system(.title2, design: .monospaced).weight(.bold))
            }
            .frame(width: 112, height: 112)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var color: Color {
        switch value {
        case 0..<0.55: return .green
        case 0.55..<0.8: return .yellow
        default: return .red
        }
    }
}

private struct StatCard: View {
    enum ValueStyle {
        case large
        case body
    }

    var title: String
    var value: String
    var detail: String
    var valueStyle: ValueStyle = .large

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(valueFont)
                .lineLimit(valueStyle == .large ? 1 : 2)
                .minimumScaleFactor(0.75)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 89, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var valueFont: Font {
        switch valueStyle {
        case .large:
            return .system(.largeTitle, design: .monospaced).weight(.bold)
        case .body:
            return .system(.body, design: .monospaced).weight(.semibold)
        }
    }
}

private struct TrendCard: View {
    var title: String
    var values: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            GeometryReader { proxy in
                let plotInsets = EdgeInsets(top: 8, leading: 42, bottom: 24, trailing: 12)
                let plot = CGRect(
                    x: plotInsets.leading,
                    y: plotInsets.top,
                    width: max(1, proxy.size.width - plotInsets.leading - plotInsets.trailing),
                    height: max(1, proxy.size.height - plotInsets.top - plotInsets.bottom)
                )

                ZStack {
                    ForEach([0.0, 0.5, 1.0], id: \.self) { tick in
                        let y = plot.minY + plot.height * (1 - CGFloat(tick))
                        Path { path in
                            path.move(to: CGPoint(x: plot.minX, y: y))
                            path.addLine(to: CGPoint(x: plot.maxX, y: y))
                        }
                        .stroke(Color.secondary.opacity(tick == 0 ? 0.3 : 0.16), lineWidth: 1)
                        Text("\(Int(tick * 100))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .position(x: 18, y: y)
                    }

                    Path { path in
                        path.move(to: CGPoint(x: plot.minX, y: plot.minY))
                        path.addLine(to: CGPoint(x: plot.minX, y: plot.maxY))
                        path.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
                    }
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)

                    ForEach([0.0, 0.5, 1.0], id: \.self) { tick in
                        let x = plot.minX + plot.width * CGFloat(tick)
                        Path { path in
                            path.move(to: CGPoint(x: x, y: plot.maxY))
                            path.addLine(to: CGPoint(x: x, y: plot.maxY + 4))
                        }
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                    }

                    Text("旧")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: plot.minX, y: plot.maxY + 15)
                    Text("现在")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: plot.maxX - 10, y: plot.maxY + 15)

                    Path { path in
                        guard values.count > 1 else { return }
                        for (index, value) in values.enumerated() {
                            let x = plot.minX + plot.width * CGFloat(index) / CGFloat(values.count - 1)
                            let y = plot.minY + plot.height * (1 - CGFloat(min(max(value, 0), 1)))
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                .background(Color.accentColor.opacity(0.05))
            }
            .frame(height: 120)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CPUCoreBarChart: View {
    var values: [Double]

    var body: some View {
        GeometryReader { proxy in
            let plotInsets = EdgeInsets(top: 12, leading: 42, bottom: 26, trailing: 12)
            let plot = CGRect(
                x: plotInsets.leading,
                y: plotInsets.top,
                width: max(1, proxy.size.width - plotInsets.leading - plotInsets.trailing),
                height: max(1, proxy.size.height - plotInsets.top - plotInsets.bottom)
            )
            let count = max(values.count, 1)
            let barGap: CGFloat = count > 16 ? 3 : 6
            let barWidth = max(4, (plot.width - CGFloat(count - 1) * barGap) / CGFloat(count))

            ZStack {
                if values.isEmpty {
                    Text("等待下一次采样")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach([0.0, 0.5, 1.0], id: \.self) { tick in
                        let y = plot.minY + plot.height * (1 - CGFloat(tick))
                        Path { path in
                            path.move(to: CGPoint(x: plot.minX, y: y))
                            path.addLine(to: CGPoint(x: plot.maxX, y: y))
                        }
                        .stroke(Color.secondary.opacity(tick == 0 ? 0.3 : 0.16), lineWidth: 1)
                        Text("\(Int(tick * 100))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .position(x: 18, y: y)
                    }

                    ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                        let clamped = min(max(value, 0), 1)
                        let barHeight = max(2, plot.height * CGFloat(clamped))
                        let x = plot.minX + CGFloat(index) * (barWidth + barGap)
                        let y = plot.maxY - barHeight

                        RoundedRectangle(cornerRadius: min(4, barWidth / 2))
                            .fill(usageColor(clamped))
                            .frame(width: barWidth, height: barHeight)
                            .position(x: x + barWidth / 2, y: y + barHeight / 2)
                            .help("逻辑核心 \(index): \(Int(clamped * 100))%")

                        if values.count <= 24 {
                            Text("\(index)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .position(x: x + barWidth / 2, y: plot.maxY + 12)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func usageColor(_ value: Double) -> Color {
        switch value {
        case 0..<0.55: return .green
        case 0.55..<0.8: return .yellow
        default: return .red
        }
    }
}
