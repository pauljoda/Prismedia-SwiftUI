import SwiftUI

struct EntityDetailMediaChipsView: View {
    let badges: [VideoPlaybackBadge]

    var body: some View {
        VideoStatusChips(
            badges: badges,
            contentHorizontalPadding: 0
        )
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
