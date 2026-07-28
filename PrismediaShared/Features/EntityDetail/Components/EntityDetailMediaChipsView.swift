import SwiftUI

struct EntityDetailMediaChipsView: View {
    let badges: [VideoPlaybackBadge]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PrismediaSpacing.small) {
                ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                    EntityDetailStatusChip(
                        title: badge.label,
                        systemImage: badge.systemImage ?? "info.circle",
                        tint: PrismediaColor.textSecondary
                    )
                    .accessibilityLabel(badge.label)
                }
            }
        }
        .accessibilityIdentifier("entity-detail.media-badges")
    }
}

#if DEBUG
    #Preview("Entity Detail Media Chips") {
        EntityDetailMediaChipsView(
            badges: [
                .init(label: "4K", systemImage: "rectangle.inset.filled", tone: .neutral),
                .init(label: "HEVC", systemImage: "film", tone: .neutral),
                .init(label: "MKV", systemImage: "shippingbox", tone: .neutral),
            ]
        )
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
