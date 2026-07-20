import SwiftUI

struct ThumbnailBadge: View {
    let systemImage: String?
    let label: String?
    let glassTint: Color
    let iconAfterLabel: Bool

    var body: some View {
        HStack(spacing: PrismediaSpacing.extraSmall) {
            if iconAfterLabel {
                labelView
                iconView
            } else {
                iconView
                labelView
            }
        }
        .font(PrismediaTypography.badge)
        .padding(.horizontal, PrismediaSpacing.extraSmall)
        .padding(.vertical, PrismediaSpacing.extraExtraSmall)
        .glassEffect(
            .regular.tint(glassTint),
            in: .rect(cornerRadius: PrismediaRadius.badge)
        )
    }

    @ViewBuilder
    private var iconView: some View {
        if let systemImage {
            Image(systemName: systemImage)
        }
    }

    @ViewBuilder
    private var labelView: some View {
        if let label {
            Text(label)
        }
    }
}

#if DEBUG
    #Preview("Thumbnail Badge") {
        ThumbnailBadge(
            systemImage: "play.fill",
            label: "4K",
            glassTint: PrismediaColor.accent,
            iconAfterLabel: false
        )
        .padding(PrismediaSpacing.large)
        .background(PrismediaBackdrop())
    }
#endif
