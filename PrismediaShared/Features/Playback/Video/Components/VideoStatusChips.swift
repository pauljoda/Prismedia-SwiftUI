import SwiftUI

struct VideoStatusChips: View {
    let badges: [VideoPlaybackBadge]
    var overlaysVideo = false
    var contentHorizontalPadding = PrismediaSpacing.medium
    var scrollAnchor: UnitPoint = .leading
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    var body: some View {
        GlassEffectContainer(spacing: PrismediaSpacing.small) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PrismediaSpacing.small) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                        HStack(spacing: PrismediaSpacing.extraSmall) {
                            if let systemImage = badge.systemImage { Image(systemName: systemImage) }
                            Text(badge.label)
                        }
                        .font(PrismediaTypography.compactCaptionEmphasized)
                        .padding(.horizontal, PrismediaSpacing.small)
                        .padding(.vertical, PrismediaSpacing.extraSmall)
                        .frame(minHeight: PrismediaSpacing.extraExtraLarge)
                        .glassEffect(
                            .regular.tint(tint(for: badge.tone)),
                            in: .capsule
                        )
                        .accessibilityLabel(badge.label)
                    }
                }
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.vertical, PrismediaSpacing.small)
            }
            .defaultScrollAnchor(scrollAnchor)
        }
        .accessibilityIdentifier("video-detail.media-badges")
    }

    private func tint(for tone: VideoPlaybackBadge.Tone) -> Color {
        let color =
            switch tone {
            case .direct: PrismediaColor.success
            case .transcode: PrismediaColor.warning
            case .neutral: artworkPrimaryAccent
            case .premium: PrismediaColor.spectrumYellow
            }
        return color.opacity(overlaysVideo ? 0.72 : 0.5)
    }
}

#if DEBUG
    #Preview("Video Status Chips · Dark Content") {
        VideoStatusChips(badges: previewBadges)
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
    }

    #Preview("Video Status Chips · Bright Media") {
        ZStack {
            LinearGradient(colors: [.white, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            VideoStatusChips(badges: previewBadges, overlaysVideo: true)
        }
    }

    #Preview("Video Status Chips · Dark Media") {
        ZStack {
            LinearGradient(colors: [.black, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
            VideoStatusChips(badges: previewBadges, overlaysVideo: true)
        }
    }

    #Preview("Video Status Chips · Accessibility") {
        VideoStatusChips(badges: previewBadges)
            .background(PrismediaBackdrop())
            .environment(\.dynamicTypeSize, .accessibility3)
    }

    private let previewBadges = [
        VideoPlaybackBadge(label: "Direct Play", systemImage: "play.rectangle", tone: .direct),
        VideoPlaybackBadge(label: "4K", tone: .neutral),
        VideoPlaybackBadge(label: "Dolby Vision", systemImage: "sparkles", tone: .premium),
    ]
#endif
