import Foundation

public enum FileSizeFormatting {
    public static func sizeText(kilobytes: Int64) -> String {
        if kilobytes >= 1_048_576 {
            return String(format: "%.2f GB", Double(kilobytes) / 1_048_576.0)
        }
        if kilobytes >= 1024 {
            return String(format: "%.0f MB", Double(kilobytes) / 1024.0)
        }
        if kilobytes > 0 {
            return "\(kilobytes) KB"
        }
        return "N/A"
    }

    public static func durationText(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0s" }
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 || hours > 0 { parts.append("\(minutes)m") }
        parts.append("\(secs)s")
        return parts.joined()
    }
}
