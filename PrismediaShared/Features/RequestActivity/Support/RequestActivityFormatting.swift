import Foundation

public enum RequestActivityFormatting {
    public static func bytes(_ value: Int64) -> String {
        value.formatted(.byteCount(style: .file))
    }

    public static func speed(_ value: Double) -> String {
        guard value > 0 else { return "0 B/s" }
        return "\(Int64(value).formatted(.byteCount(style: .file)))/s"
    }

    public static func eta(_ seconds: Int64) -> String {
        guard seconds > 0 else { return "Now" }
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(max(1, minutes))m"
    }

    public static func relative(_ date: Date?, referenceDate: Date) -> String {
        guard let date else { return "never" }
        let seconds = Int(date.timeIntervalSince(referenceDate))
        let magnitude = abs(seconds)
        if magnitude < 60 { return "now" }
        let value: Int
        let unit: String
        if magnitude < 3_600 {
            value = max(1, magnitude / 60)
            unit = "m"
        } else if magnitude < 86_400 {
            value = magnitude / 3_600
            unit = "h"
        } else {
            value = magnitude / 86_400
            unit = "d"
        }
        return seconds < 0 ? "\(value)\(unit) ago" : "in \(value)\(unit)"
    }

    public static func nextSearch(_ date: Date?, referenceDate: Date) -> String {
        guard let date else { return "due now" }
        let seconds = Int(date.timeIntervalSince(referenceDate))
        guard seconds > 0 else { return "due now" }
        if seconds < 3_600 { return "in \(max(1, seconds / 60))m" }
        if seconds < 86_400 { return "in \(seconds / 3_600)h" }
        return "in \(seconds / 86_400)d"
    }
}
