enum VideoPlaybackScrubPolicy {
    private static let panDamping = 20_000.0

    static func targetTime(
        origin: Double,
        translation: Double,
        duration: Double
    ) -> Double {
        guard duration > 0 else { return max(0, origin) }
        let target = origin + translation * duration / panDamping
        return max(0, min(target, duration))
    }
}
