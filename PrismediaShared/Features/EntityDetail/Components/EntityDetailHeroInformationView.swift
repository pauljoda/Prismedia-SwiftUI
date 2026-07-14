import SwiftUI

struct EntityDetailHeroInformationView: View {
    let presentation: EntityDetailPresentation
    let previewPath: String?
    let showsArtwork: Bool
    let actions: [EntityDetailAction]
    let isMutating: Bool
    let canMutate: Bool
    let isActionEnabled: (EntityDetailAction) -> Bool
    let actionHint: (EntityDetailAction) -> String
    let onRatingChange: (Int?) -> Void
    let onAction: (EntityDetailAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            EntityDetailHeaderView(
                presentation: presentation,
                previewPath: previewPath,
                showsArtwork: showsArtwork,
                isMutating: isMutating,
                canMutate: canMutate,
                onRatingChange: onRatingChange
            )

            EntityDetailPrimaryActionsView(
                actions: actions,
                horizontalPadding: horizontalPadding,
                isEnabled: isActionEnabled,
                accessibilityHint: actionHint,
                onAction: onAction
            )
        }
        .padding(.bottom, PrismediaSpacing.extraExtraLarge)
        .accessibilityIdentifier("entity-detail.hero-information")
    }

    private var horizontalPadding: CGFloat {
        #if os(tvOS)
            72
        #else
            20
        #endif
    }
}

#if DEBUG
    #Preview("Entity Detail · Hero Information") {
        let presentation = EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail)
        PreviewShell {
            ScrollView {
                EntityDetailHeroInformationView(
                    presentation: presentation,
                    previewPath: "/preview/poster.jpg",
                    showsArtwork: true,
                    actions: presentation.primaryActions,
                    isMutating: false,
                    canMutate: true,
                    isActionEnabled: { _ in true },
                    actionHint: { _ in "Opens this item" },
                    onRatingChange: { _ in },
                    onAction: { _ in }
                )
            }
        }
    }
#endif
