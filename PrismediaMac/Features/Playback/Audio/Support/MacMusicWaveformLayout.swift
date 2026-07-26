#if os(macOS)
    import CoreGraphics
    import Foundation

    enum MacMusicWaveformLayout {
        static let maximumStripWidth: CGFloat = 8_192

        static func stripWidth(
            pairCount: Int,
            duration: Double,
            viewportWidth: CGFloat
        ) -> CGFloat {
            guard viewportWidth > 0 else { return 0 }
            let naturalWidth = CGFloat(max(1, pairCount) * 2)
            let durationWidth = CGFloat(max(0.001, duration) * 10)
            let preferredWidth = max(naturalWidth, viewportWidth * 6, durationWidth)
            return max(viewportWidth, min(preferredWidth, maximumStripWidth))
        }

        static func time(
            from startTime: Double,
            translation: CGFloat,
            stripWidth: CGFloat,
            duration: Double
        ) -> Double {
            guard stripWidth > 0, duration > 0 else { return max(0, startTime) }
            return max(0, min(duration, startTime - Double(translation / stripWidth) * duration))
        }
    }
#endif
