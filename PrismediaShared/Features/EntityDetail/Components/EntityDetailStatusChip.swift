import SwiftUI

struct EntityDetailStatusChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(PrismediaTypography.captionEmphasized)
            .foregroundStyle(tint)
            .padding(.horizontal, PrismediaSpacing.medium)
            .padding(.vertical, PrismediaSpacing.small)
            .background(PrismediaColor.elevatedContentBackground.opacity(0.9))
            .overlay {
                RoundedRectangle(cornerRadius: PrismediaRadius.badge, style: .continuous)
                    .stroke(tint.opacity(0.35), lineWidth: PrismediaLayout.hairline)
            }
            .clipShape(.rect(cornerRadius: PrismediaRadius.badge))
    }
}
#if DEBUG
    #Preview("Status Chip") {
        EntityDetailStatusChip(title: "Favorite", systemImage: "heart.fill", tint: PrismediaColor.accent)
            .padding(PrismediaSpacing.large)
    }
#endif
