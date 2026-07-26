#if os(macOS)
    import SwiftUI

    struct EntityDetailPlatformActionsView: View {
        let presentation: EntityDetailPresentation
        let palette: ArtworkPalette?
        let horizontalPadding: CGFloat
        let isActionSupported: (EntityDetailAction) -> Bool
        let isActionEnabled: (EntityDetailAction) -> Bool
        let actionHint: (EntityDetailAction) -> String
        let onAction: (EntityDetailAction) -> Void

        var body: some View {
            EntityDetailModificationActionsView(
                presentation: presentation,
                palette: palette,
                horizontalPadding: horizontalPadding,
                isActionSupported: isActionSupported,
                isActionEnabled: isActionEnabled,
                actionHint: actionHint,
                onAction: onAction
            )
        }
    }

    #if DEBUG
        #Preview("Mac Entity Detail Actions") {
            EntityDetailPlatformActionsView(
                presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
                palette: nil,
                horizontalPadding: PrismediaSpacing.extraLarge,
                isActionSupported: { _ in true },
                isActionEnabled: { _ in true },
                actionHint: { _ in "Updates this entity" },
                onAction: { _ in }
            )
            .padding(.vertical)
        }
    #endif
#endif
