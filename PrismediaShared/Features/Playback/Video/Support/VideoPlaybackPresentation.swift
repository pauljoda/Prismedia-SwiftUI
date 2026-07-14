import CoreMedia
import Foundation

enum VideoPlaybackPresentation {
    static func clockTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let remainingSeconds = total % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds) }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    static func bufferedEnd(ranges: [CMTimeRange], duration: Double) -> Double {
        let furthestEnd =
            ranges.map { CMTimeRangeGetEnd($0).seconds }
            .filter(\.isFinite)
            .max() ?? 0
        return max(0, min(furthestEnd, duration))
    }
}
