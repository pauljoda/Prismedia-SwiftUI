enum VideoPlaybackTimelineAccessibility {
    private static let adjustmentInterval = 10.0
    static func adjustedTime(from currentTime: Double, duration: Double, incrementing: Bool) -> Double {
        guard duration.isFinite, duration > 0 else { return 0 }
        let currentTime = currentTime.isFinite ? currentTime : 0
        return max(0, min(duration, currentTime + (incrementing ? adjustmentInterval : -adjustmentInterval)))
    }
    static func value(currentTime: Double, duration: Double) -> String {
        let current = VideoPlaybackPresentation.clockTime(currentTime)
        guard duration.isFinite, duration > 0 else { return current }
        return "\(current) of \(VideoPlaybackPresentation.clockTime(duration))"
    }
}
