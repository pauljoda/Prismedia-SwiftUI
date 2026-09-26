#if os(iOS) || os(macOS)
    import SwiftUI

    /// Sheet that creates a manual Collection and hands it to the presenter before closing, so the
    /// presenter can open the new Collection underneath the departing sheet.
    struct NewCollectionSheet: View {
        let creator: any CollectionCreating
        let onCreated: (EntityThumbnail) -> Void

        var body: some View {
            NavigationStack {
                NewCollectionForm(showsCancelAction: true) { draft in
                    let collection = try await creator.createCollection(from: draft)
                    onCreated(collection)
                }
            }
        }
    }

    #if DEBUG
        #Preview("New Collection Sheet") {
            PreviewShell(signedIn: true) {
                Color.clear
                    .sheet(isPresented: .constant(true)) {
                        NewCollectionSheet(creator: CollectionCreationPreviewService()) { _ in }
                    }
            }
        }
    #endif
#endif
