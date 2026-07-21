import SwiftUI

#if !os(tvOS)

    struct VideoFilmstripMarkerButton: View {
        let marker: EntityMarker
        let accent: Color
        let stripHeight: CGFloat
        let offsetX: CGFloat
        let onSelect: () -> Void

        var body: some View {
            Button(action: onSelect) {
                ZStack {
                    Color.clear
                    Rectangle()
                        .fill(accent.opacity(0.65))
                        .frame(width: 1, height: stripHeight)
                }
                .frame(width: PrismediaLayout.minimumHitTarget, height: stripHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: offsetX)
            .accessibilityLabel(marker.title)
            .accessibilityValue("At \(VideoPlaybackPresentation.clockTime(marker.seconds))")
            .accessibilityHint("Seeks playback to this marker")
            .accessibilityIdentifier("video-filmstrip.marker.\(marker.id)")
        }
    }

#endif
