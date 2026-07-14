import SwiftUI

struct DashboardSectionHeader: View {
    @ScaledMetric(relativeTo: .headline) private var iconSize: CGFloat = 28

    let title: String
    let systemImage: String
    let colorRole: DashboardSectionColorRole
    let onSelect: (() -> Void)?

    var body: some View {
        if let onSelect {
            Button(action: onSelect) {
                row
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens \(title)")
            .accessibilityIdentifier("dashboard.section.\(title.lowercased())")
        } else {
            row
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var row: some View {
        HStack(spacing: PrismediaSpacing.small) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(PrismediaColor.onMedia)
                .frame(width: iconSize, height: iconSize)
                .background(
                    LinearGradient(
                        colors: colorRole.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: .circle
                )
                .accessibilityHidden(true)

            Text(title)
                .font(PrismediaTypography.subsectionTitle)
                .foregroundStyle(PrismediaColor.textPrimary)

            if onSelect != nil {
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PrismediaColor.textMuted)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: PrismediaSpacing.small)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: PrismediaLayout.minimumHitTarget,
            alignment: .leading
        )
        .contentShape(Rectangle())
    }
}

#if DEBUG
    #Preview("Dashboard Section Header · Rainbow") {
        VStack(spacing: PrismediaSpacing.small) {
            DashboardSectionHeader(
                title: "Movies",
                systemImage: "movieclapper",
                colorRole: .movie,
                onSelect: {}
            )
            DashboardSectionHeader(
                title: "Series",
                systemImage: "rectangle.stack",
                colorRole: .series,
                onSelect: {}
            )
        }
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
