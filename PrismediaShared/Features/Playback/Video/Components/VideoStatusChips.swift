import SwiftUI

struct VideoStatusChips: View {
    let badges: [VideoPlaybackBadge]
    var overlaysVideo = false
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PrismediaSpacing.small) {
                ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                    HStack(spacing: PrismediaSpacing.extraSmall) {
                        if let systemImage = badge.systemImage { Image(systemName: systemImage) }
                        Text(badge.label)
                    }
                    .font(PrismediaTypography.compactCaptionEmphasized)
                    .foregroundStyle(chipForeground)
                    .padding(.horizontal, PrismediaSpacing.small)
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                    .frame(minHeight: PrismediaSpacing.extraExtraLarge)
                    .background(chipBackground, in: .capsule)
                    .overlay {
                        Capsule().stroke(chipBorder, lineWidth: PrismediaLayout.hairline)
                    }
                    .accessibilityLabel(badge.label)
                }
            }
            .padding(.horizontal, PrismediaSpacing.medium)
            .padding(.vertical, PrismediaSpacing.small)
        }
        .accessibilityIdentifier("video-detail.media-badges")
    }

    private var chipBackground: Color {
        overlaysVideo ? Color.black.opacity(0.58) : PrismediaColor.controlFill
    }

    private var chipBorder: Color {
        overlaysVideo ? Color.white.opacity(0.18) : PrismediaColor.borderSubtle
    }

    private var chipForeground: Color {
        overlaysVideo ? .white : PrismediaColor.textPrimary
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
