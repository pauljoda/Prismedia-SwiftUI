#if os(iOS)
import SwiftUI

struct EntityDetailPlatformActionsView: View {
    let presentation: EntityDetailPresentation
    let isMutating: Bool
    let canMutate: Bool
    let palette: ArtworkPalette?
    let horizontalPadding: CGFloat
    let isActionSupported: (EntityDetailAction) -> Bool
    let isActionEnabled: (EntityDetailAction) -> Bool
    let actionHint: (EntityDetailAction) -> String
    let onRatingChange: (Int?) -> Void
    let onAction: (EntityDetailAction) -> Void

    var body: some View {
        EmptyView()
    }
}

#Preview("iOS Entity Detail Actions") {
    EntityDetailPlatformActionsView(
        presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
        isMutating: false,
        canMutate: true,
        palette: nil,
        horizontalPadding: 20,
        isActionSupported: { _ in true },
        isActionEnabled: { _ in true },
        actionHint: { _ in "Updates this entity" },
        onRatingChange: { _ in },
        onAction: { _ in }
    )
}
#endif
