import SwiftUI

struct DashboardHeroMetadataChipsView: View {
    let labels: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PrismediaSpacing.small) {
                chips
            }
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                chips
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var chips: some View {
        ForEach(labels, id: \.self) { label in
            Text(label)
                .font(PrismediaTypography.compactCaptionEmphasized)
                .foregroundStyle(PrismediaColor.onMedia)
                .padding(.horizontal, PrismediaSpacing.extraSmall)
                .padding(.vertical, PrismediaSpacing.extraExtraSmall)
                .background(
                    PrismediaColor.background.opacity(0.52),
                    in: .capsule
                )
        }
    }
}

#if DEBUG
    #Preview("Dashboard Hero Metadata · Accessibility") {
        DashboardHeroMetadataChipsView(
            labels: ["Movie", "Science Fiction", "1h 56m"]
        )
        .padding()
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
        .preferredColorScheme(.dark)
    }
#endif
