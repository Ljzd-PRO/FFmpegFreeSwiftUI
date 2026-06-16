import SwiftUI

public struct PerformanceView: View {
    @State private var snapshot = PerformanceSnapshot.empty
    @State private var refreshTask: Task<Void, Never>?
    private let monitor = PerformanceMonitor()

    public init() {}

    public var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 16) {
            metric("CPU Load", snapshot.cpuLoadText)
            metric("内存", snapshot.memoryText)
            metric("磁盘", snapshot.diskText)
            metric("进程数", snapshot.processCountText)
            metric("GPU/显存", snapshot.gpuText)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            refreshTask?.cancel()
            refreshTask = Task {
                while !Task.isCancelled {
                    let next = await monitor.snapshot()
                    await MainActor.run { snapshot = next }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }
        .onDisappear {
            refreshTask?.cancel()
            refreshTask = nil
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title)
                .font(.headline)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
