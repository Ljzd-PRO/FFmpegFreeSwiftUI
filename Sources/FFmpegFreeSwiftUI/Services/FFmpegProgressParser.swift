import Foundation

public struct FFmpegProgressParser: Sendable {
    public static let errorKeywords = [
        "Error", "Invalid", "cannot", "failed", "not supported", "require", "must be",
        "Could not", "is experimental", "if you want to use it", "Nothing was written"
    ]

    public init() {}

    public func parse(line: String, into progress: inout EncodingProgress, startedAt: Date?) -> Bool {
        var didUpdate = false
        if let duration = firstMatch(#"Duration:\s*(\d+:\d{2}:\d{2}\.\d{2})"#, in: line) {
            progress.totalTime = Self.timeInterval(from: duration)
            didUpdate = true
        }
        if line.hasPrefix("frame=") || line.hasPrefix("size=") || line.contains(" time=") {
            if let frame = namedValue(#"frame=\s*(\d+)"#, in: line) { progress.frame = frame }
            if let fps = namedValue(#"fps=\s*([\d\.]+)"#, in: line) { progress.fps = fps }
            if let q = namedValue(#"q=\s*([\-\d\.]+)"#, in: line), isMeaningfulQuality(q) {
                progress.quality = q
            }
            if let size = sizeMatch(in: line) {
                progress.outputSizeKB = size
                progress.outputSizeText = FileSizeFormatting.sizeText(kilobytes: size)
            }
            if let time = namedValue(#"time=\s*(\d+:\d{2}:\d{2}\.\d{2})"#, in: line) {
                progress.currentTime = Self.timeInterval(from: time)
            }
            if let bitrate = namedValue(#"bitrate=\s*([\d\.]+)\s*kbits/s"#, in: line) {
                progress.bitrate = "\(bitrate) kbps"
            }
            if let speed = namedValue(#"speed=\s*([\d\.eE\+\-]+)\s*x"#, in: line) {
                progress.speed = speed + "x"
            }
            recalculate(progress: &progress, startedAt: startedAt)
            didUpdate = true
        }
        return didUpdate
    }

    public func isErrorLine(_ line: String) -> Bool {
        Self.errorKeywords.contains { keyword in
            line.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    public static func timeInterval(from value: String) -> TimeInterval {
        let pieces = value.split(separator: ":")
        guard pieces.count == 3,
              let hours = Double(pieces[0]),
              let minutes = Double(pieces[1]),
              let seconds = Double(pieces[2]) else {
            return 0
        }
        return hours * 3600 + minutes * 60 + seconds
    }

    private func recalculate(progress: inout EncodingProgress, startedAt: Date?) {
        if progress.totalTime > 0, progress.currentTime > 0 {
            progress.percent = min(max(progress.currentTime / progress.totalTime, 0), 1)
        }
        if progress.percent > 0, progress.percent < 1, progress.outputSizeKB > 0 {
            let estimated = Int64(Double(progress.outputSizeKB) / progress.percent)
            progress.estimatedSizeText = " - " + FileSizeFormatting.sizeText(kilobytes: estimated)
        }
        if progress.totalTime > 0,
           progress.currentTime > 0,
           let speed = Double(progress.speed.replacingOccurrences(of: "x", with: "")),
           speed > 0 {
            progress.remainingText = FileSizeFormatting.durationText((progress.totalTime - progress.currentTime) / speed)
        }
        if let startedAt {
            progress.elapsedText = FileSizeFormatting.durationText(Date().timeIntervalSince(startedAt))
        }
    }

    private func firstMatch(_ pattern: String, in line: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: line) else {
            return nil
        }
        return String(line[range])
    }

    private func namedValue(_ pattern: String, in line: String) -> String? {
        firstMatch(pattern, in: line)
    }

    private func isMeaningfulQuality(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Double(normalized), number.isFinite else { return false }
        return abs(number) > 0.000_001
    }

    private func sizeMatch(in line: String) -> Int64? {
        guard let regex = try? NSRegularExpression(pattern: #"size=\s*(\d+)\s*([KMG]iB)"#),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              match.numberOfRanges == 3,
              let valueRange = Range(match.range(at: 1), in: line),
              let unitRange = Range(match.range(at: 2), in: line),
              let value = Int64(line[valueRange]) else {
            return nil
        }
        switch line[unitRange].uppercased() {
        case "MIB":
            return value * 1024
        case "GIB":
            return value * 1024 * 1024
        default:
            return value
        }
    }
}
