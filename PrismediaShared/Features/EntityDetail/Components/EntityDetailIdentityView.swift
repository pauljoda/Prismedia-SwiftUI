import SwiftUI

struct EntityDetailIdentityView: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    let presentation: EntityDetailPresentation
    let isMutating: Bool
    let canMutate: Bool
    let horizontalPadding: CGFloat
    let onRatingChange: (Int?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Text(presentation.detail.kind.displayLabel.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(artworkPrimaryAccent)

            Text(presentation.detail.title)
                .font(titleFont)
                .foregroundStyle(artworkPrimaryAccent)
                .prismediaTextSelection()

            #if !os(tvOS)
                if presentation.hasRatingCapability {
                    EntityDetailStarRatingControl(
                        value: presentation.rating,
                        isDisabled: isMutating || !canMutate,
                        onChange: onRatingChange
                    )
                    .prismediaFocusSection()
                }
            #endif

            if !presentation.flagItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PrismediaSpacing.small) {
                        ForEach(presentation.flagItems) { flag in
                            EntityDetailStatusChip(
                                title: flag.title,
                                systemImage: flag.systemImage,
                                tint: tint(for: flag.tone)
                            )
                        }
                    }
                }
            }

            if let description = presentation.description {
                Text(description)
                    .font(PrismediaTypography.body)
                    .foregroundStyle(artworkSecondaryText)
                    .lineSpacing(4)
                    .lineLimit(EntityDetailHeroArtworkPolicy.summaryLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .prismediaTextSelection()
                    .accessibilityIdentifier("entity-detail.summary")
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    private var titleFont: Font {
        #if os(tvOS)
            .system(size: 54, weight: .bold)
        #else
            .largeTitle.bold()
        #endif
    }

    private func tint(for tone: EntityDetailFlagTone) -> Color {
        switch tone {
        case .accent: artworkPrimaryAccent
        case .destructive: PrismediaColor.destructive
        case .info: PrismediaColor.info
        }
    }
}
#if DEBUG
    #Preview("Entity Identity") {
        EntityDetailIdentityView(
            presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
            isMutating: false,
            canMutate: true,
            horizontalPadding: PrismediaSpacing.extraLarge,
            onRatingChange: { _ in }
        )
        .padding(.vertical)
    }
#endif
