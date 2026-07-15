import SwiftUI

struct EntityDetailCreditSubtitleView: View {
    let subtitle: String

    var body: some View {
        Text(subtitle)
            .font(PrismediaTypography.badge)
            .foregroundStyle(PrismediaColor.textSecondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, PrismediaSpacing.small)
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .frame(maxWidth: .infinity)
            .background(PrismediaColor.controlFill.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous)
                    .stroke(PrismediaColor.border, lineWidth: PrismediaLayout.hairline)
            }
            .clipShape(RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous))
    }
}

#if DEBUG
    #Preview("Credit Subtitle") {
        EntityDetailCreditSubtitleView(subtitle: "Director")
            .frame(width: 132)
            .padding(PrismediaSpacing.large)
            .background(PrismediaBackdrop())
    }
#endif
