import SwiftUI

struct ThumbnailBadge: View {
    let systemImage: String?
    let label: String?
    let tint: Color
    let background: Color
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
        .foregroundStyle(tint)
        .padding(.horizontal, PrismediaSpacing.extraSmall)
        .padding(.vertical, PrismediaSpacing.extraExtraSmall)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: PrismediaLayout.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous))
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
            tint: PrismediaColor.accent,
            background: PrismediaColor.controlFill,
            iconAfterLabel: false
        )
        .padding(PrismediaSpacing.large)
        .background(PrismediaBackdrop())
    }
#endif
