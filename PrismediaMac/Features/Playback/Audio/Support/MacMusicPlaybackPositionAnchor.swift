#if os(macOS)
    import Foundation

    struct MacMusicPlaybackPositionAnchor: Equatable {
        private(set) var elapsedTime = 0.0
        private(set) var date = Date.now

        mutating func synchronize(to elapsedTime: Double, at date: Date = .now) {
            self.elapsedTime = max(0, elapsedTime.isFinite ? elapsedTime : 0)
            self.date = date
        }

        func position(
            at timelineDate: Date,
            isPlaying: Bool,
            playbackRate: Float,
            duration: Double
        ) -> Double {
            let elapsedSinceAnchor = isPlaying
                ? max(0, timelineDate.timeIntervalSince(date)) * Double(playbackRate)
                : 0
            return min(max(0, elapsedTime + elapsedSinceAnchor), max(0, duration))
        }
    }
#endif
