#if os(iOS)
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
        EmptyView()
    }
}

#Preview("iOS Entity Detail Actions") {
    EntityDetailPlatformActionsView(
        presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
        palette: nil,
        horizontalPadding: 20,
        isActionSupported: { _ in true },
        isActionEnabled: { _ in true },
        actionHint: { _ in "Updates this entity" },
        onAction: { _ in }
    )
}
#endif
