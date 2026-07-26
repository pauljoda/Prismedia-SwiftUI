#if os(iOS)
    import SwiftUI

    struct EntityDetailPlatformActionsView: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        let presentation: EntityDetailPresentation
        let palette: ArtworkPalette?
        let horizontalPadding: CGFloat
        let isActionSupported: (EntityDetailAction) -> Bool
        let isActionEnabled: (EntityDetailAction) -> Bool
        let actionHint: (EntityDetailAction) -> String
        let onAction: (EntityDetailAction) -> Void

        @ViewBuilder
        var body: some View {
            if horizontalSizeClass == .regular, presentation.detail.kind.isAudioEntity {
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
    }

    extension EntityKind {
        fileprivate var isAudioEntity: Bool {
            self == .audio || self == .audioTrack
        }
    }

    #if DEBUG
        #Preview("iOS Entity Detail Actions") {
            EntityDetailPlatformActionsView(
                presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
                palette: nil,
                horizontalPadding: PrismediaSpacing.extraLarge,
                isActionSupported: { _ in true },
                isActionEnabled: { _ in true },
                actionHint: { _ in "Updates this entity" },
                onAction: { _ in }
            )
        }
    #endif
#endif
