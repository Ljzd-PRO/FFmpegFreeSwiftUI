import Darwin
import Foundation

public struct PerformanceSnapshot: Equatable, Sendable {
    public var cpuUsage: Double
    public var coreUsages: [Double]
    public var loadAverageText: String
    public var memoryUsedBytes: UInt64
    public var memoryTotalBytes: UInt64
    public var diskUsedBytes: UInt64
    public var diskTotalBytes: UInt64
    public var runningQueueTasks: Int
    public var pendingQueueTasks: Int
    public var sampledAt: Date

    public static let empty = PerformanceSnapshot(
        cpuUsage: 0,
        coreUsages: [],
        loadAverageText: "N/A",
        memoryUsedBytes: 0,
        memoryTotalBytes: 0,
        diskUsedBytes: 0,
        diskTotalBytes: 0,
        runningQueueTasks: 0,
        pendingQueueTasks: 0,
        sampledAt: Date()
    )

    public var memoryUsage: Double {
        guard memoryTotalBytes > 0 else { return 0 }
        return min(max(Double(memoryUsedBytes) / Double(memoryTotalBytes), 0), 1)
    }

    public var diskUsage: Double {
        guard diskTotalBytes > 0 else { return 0 }
        return min(max(Double(diskUsedBytes) / Double(diskTotalBytes), 0), 1)
    }

    public var memoryText: String {
        "\(FileSizeFormatting.bytesText(memoryUsedBytes)) / \(FileSizeFormatting.bytesText(memoryTotalBytes))"
    }

    public var diskText: String {
        "\(FileSizeFormatting.bytesText(diskUsedBytes)) / \(FileSizeFormatting.bytesText(diskTotalBytes))"
    }
}

public actor PerformanceMonitor {
    private var previousCPULoads: [CPULoad] = []

    public init() {}

    public func snapshot(runningQueueTasks: Int = 0, pendingQueueTasks: Int = 0) async -> PerformanceSnapshot {
        let cpu = cpuUsage()
        let memory = memoryUsage()
        let disk = diskUsage()

        return PerformanceSnapshot(
            cpuUsage: cpu.total,
            coreUsages: cpu.cores,
            loadAverageText: loadAverage(),
            memoryUsedBytes: memory.used,
            memoryTotalBytes: memory.total,
            diskUsedBytes: disk.used,
            diskTotalBytes: disk.total,
            runningQueueTasks: runningQueueTasks,
            pendingQueueTasks: pendingQueueTasks,
            sampledAt: Date()
        )
    }

    private func cpuUsage() -> (total: Double, cores: [Double]) {
        guard let current = readCPULoads(), !current.isEmpty else {
            return (0, [])
        }
        defer { previousCPULoads = current }
        guard previousCPULoads.count == current.count else {
            return (0, Array(repeating: 0, count: current.count))
        }

        let coreUsages = zip(previousCPULoads, current).map { previous, next -> Double in
            let user = next.user - previous.user
            let system = next.system - previous.system
            let nice = next.nice - previous.nice
            let idle = next.idle - previous.idle
            let total = user + system + nice + idle
            guard total > 0 else { return 0 }
            return min(max(Double(user + system + nice) / Double(total), 0), 1)
        }
        let totalUsage = coreUsages.isEmpty ? 0 : coreUsages.reduce(0, +) / Double(coreUsages.count)
        return (totalUsage, coreUsages)
    }

    private func readCPULoads() -> [CPULoad]? {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &cpuInfoCount
        )
        guard result == KERN_SUCCESS, let cpuInfo else { return nil }
        defer {
            let bytes = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), bytes)
        }

        var loads: [CPULoad] = []
        for index in 0..<Int(processorCount) {
            let offset = index * Int(CPU_STATE_MAX)
            loads.append(
                CPULoad(
                    user: UInt64(cpuInfo[offset + Int(CPU_STATE_USER)]),
                    system: UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)]),
                    idle: UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)]),
                    nice: UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])
                )
            )
        }
        return loads
    }

    private func memoryUsage() -> (used: UInt64, total: UInt64) {
        var size = MemoryLayout<UInt64>.size
        var total: UInt64 = 0
        sysctlbyname("hw.memsize", &total, &size, nil, 0)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, total) }
        let pageSize = UInt64(vm_kernel_page_size)
        let free = UInt64(stats.free_count + stats.inactive_count) * pageSize
        return (total > free ? total - free : 0, total)
    }

    private func diskUsage() -> (used: UInt64, total: UInt64) {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let free = (attrs[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
            let size = (attrs[.systemSize] as? NSNumber)?.uint64Value ?? 0
            return (size > free ? size - free : 0, size)
        } catch {
            return (0, 0)
        }
    }

    private func loadAverage() -> String {
        var loads = [Double](repeating: 0, count: 3)
        guard getloadavg(&loads, 3) == 3 else { return "N/A" }
        return String(format: "%.2f / %.2f / %.2f", loads[0], loads[1], loads[2])
    }
}

private struct CPULoad: Equatable {
    var user: UInt64
    var system: UInt64
    var idle: UInt64
    var nice: UInt64
}
