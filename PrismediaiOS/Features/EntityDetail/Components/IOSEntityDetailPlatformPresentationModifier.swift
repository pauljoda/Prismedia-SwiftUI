#if os(iOS)
import SwiftUI

struct EntityDetailPlatformPresentationModifier<EditContent: View>: ViewModifier {
    let navigationTitle: String
    let detail: EntityDetail?
    let presentation: EntityDetailPresentation?
    @Binding var editPresentation: EntityDetailEditPresentation?
    @Binding var collectionSheetPresented: Bool
    let isActionSupported: (EntityDetailAction) -> Bool
    let isActionEnabled: (EntityDetailAction) -> Bool
    let actionLabel: (EntityDetailAction) -> String
    let actionHint: (EntityDetailAction) -> String
    let onAction: (EntityDetailAction) -> Void
    @ViewBuilder let editContent: (EntityDetailEditPresentation) -> EditContent

    func body(content: Content) -> some View {
        content
            .navigationTitle(navigationTitle)
            .prismediaInlineNavigationTitle()
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if let presentation {
                    ToolbarItem(placement: .primaryAction) {
                        EntityDetailToolbarMenu(
                            actions: presentation.modificationActions.filter(isActionSupported),
                            isEnabled: isActionEnabled,
                            accessibilityLabel: actionLabel,
                            accessibilityHint: actionHint,
                            onAddToCollection: { collectionSheetPresented = true },
                            onAction: onAction
                        )
                    }
                }
            }
            .sheet(isPresented: $collectionSheetPresented) {
                if let detail {
                    AddToCollectionSheet(
                        items: [
                            CollectionEntityReference(
                                entityType: detail.kind,
                                entityID: detail.id
                            )
                        ]
                    )
                }
            }
            .sheet(item: $editPresentation, content: editContent)
    }
}

#if DEBUG
    #Preview("iOS Entity Detail Presentation") {
        @Previewable @State var editPresentation: EntityDetailEditPresentation?
        @Previewable @State var collectionSheetPresented = false
        let detail = EntityDetailPreviewFixture.detail
        Text(detail.title)
            .modifier(
                EntityDetailPlatformPresentationModifier(
                    navigationTitle: detail.title,
                    detail: detail,
                    presentation: EntityDetailPresentation(detail: detail),
                    editPresentation: $editPresentation,
                    collectionSheetPresented: $collectionSheetPresented,
                    isActionSupported: { _ in true },
                    isActionEnabled: { _ in true },
                    actionLabel: { $0.title },
                    actionHint: { _ in "Updates this entity" },
                    onAction: { _ in },
                    editContent: { _ in Text("Entity editor") }
                )
            )
    }
#endif
#endif
