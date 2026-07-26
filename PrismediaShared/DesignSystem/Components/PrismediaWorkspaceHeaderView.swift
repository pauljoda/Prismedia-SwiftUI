import SwiftUI

struct PrismediaWorkspaceHeaderView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: PrismediaSpacing.medium) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 38, height: 38)
                .background(
                    PrismediaColor.controlFill,
                    in: .rect(cornerRadius: PrismediaRadius.compact)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.compact)
                        .stroke(accent.opacity(0.42), lineWidth: PrismediaLayout.hairline)
                }

            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                Text(title)
                    .font(.title2.weight(.bold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(PrismediaColor.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
        .padding(.top, PrismediaSpacing.large)
        .padding(.bottom, PrismediaSpacing.medium)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
    #Preview("Workspace Header") {
        PrismediaWorkspaceHeaderView(
            title: "Request",
            subtitle: "Discover and add new media to your libraries.",
            systemImage: "paperplane.fill",
            accent: PrismediaColor.materialSpectrumViolet
        )
        .frame(width: 760)
        .background(PrismediaColor.background)
    }
#endif
