#if !os(tvOS)
    import SwiftUI

    struct MusicPlaybackTimeline: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @Binding var position: Double
        let duration: Double
        let onEditingChanged: (Bool) -> Void
        var showsTimeLabels = true
        var playbackRate: Float = 1

        var body: some View {
            VStack(spacing: PrismediaSpacing.extraSmall) {
                Slider(
                    value: Binding(
                        get: { min(position, duration) },
                        set: { position = $0 }
                    ),
                    in: 0...duration,
                    onEditingChanged: onEditingChanged
                )
                .tint(artworkPrimaryAccent)
                .accessibilityLabel("Playback Position")
                .accessibilityValue(
                    "\(MusicPresentation.clockTime(position)) of \(MusicPresentation.clockTime(duration))"
                )

                if showsTimeLabels {
                    HStack(alignment: .top) {
                        Text(MusicPresentation.clockTime(position))
                        Spacer()
                        remainingTimeLabel
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
        }

        private var remainingTimeLabel: some View {
            let originalRemainingTime = max(0, duration - position)
            let effectiveRemainingTime = MusicPresentation.effectiveRemainingTime(
                duration: duration,
                position: position,
                playbackRate: playbackRate
            )

            return VStack(alignment: .trailing, spacing: PrismediaSpacing.extraSmall / 2) {
                Text("−\(MusicPresentation.clockTime(effectiveRemainingTime))")

                Text("Original −\(MusicPresentation.clockTime(originalRemainingTime))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textMuted)
                    .opacity(showsAdjustedRemainingTime ? 1 : 0)
                    .accessibilityHidden(!showsAdjustedRemainingTime)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                remainingTimeAccessibilityLabel(
                    effectiveRemainingTime: effectiveRemainingTime,
                    originalRemainingTime: originalRemainingTime
                ))
        }

        private var showsAdjustedRemainingTime: Bool {
            playbackRate.isFinite
                && playbackRate > 0
                && abs(playbackRate - 1) > 0.001
        }

        private func remainingTimeAccessibilityLabel(
            effectiveRemainingTime: Double,
            originalRemainingTime: Double
        ) -> String {
            let effectiveLabel = MusicPresentation.clockTime(effectiveRemainingTime)
            guard showsAdjustedRemainingTime else {
                return "\(effectiveLabel) remaining"
            }

            let originalLabel = MusicPresentation.clockTime(originalRemainingTime)
            let rateLabel = MusicPlaybackRateOption(rate: playbackRate).label
            return "\(effectiveLabel) remaining at \(rateLabel), original \(originalLabel)"
        }
    }

    #if DEBUG
        #Preview("Music Playback Timeline · Fallback") {
            @Previewable @State var position = 78.0
            MusicPlaybackTimeline(
                position: $position,
                duration: 240,
                onEditingChanged: { _ in },
                playbackRate: 1.5
            )
            .padding()
            .background(PrismediaColor.background)
        }

        #Preview("Music Playback Timeline · Artwork Accent") {
            @Previewable @State var position = 78.0
            MusicPlaybackTimeline(
                position: $position,
                duration: 240,
                onEditingChanged: { _ in }
            )
            .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumMagenta)
            .padding()
            .background(PrismediaColor.background)
        }
    #endif
#endif
