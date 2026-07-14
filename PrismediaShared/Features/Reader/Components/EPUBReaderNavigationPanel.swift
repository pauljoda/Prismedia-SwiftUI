#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct EPUBReaderNavigationPanel: View {
        @Environment(\.dismiss) private var dismiss

        let onOpenContents: () -> Void
        let onOpenSearch: () -> Void
        let onOpenBookmarks: () -> Void

        var body: some View {
            NavigationStack {
                List {
                    Button("Table of Contents", systemImage: "list.bullet.indent", action: onOpenContents)
                        .accessibilityIdentifier("epub-reader.table-of-contents")
                    Button("Search book", systemImage: "magnifyingglass", action: onOpenSearch)
                        .accessibilityIdentifier("epub-reader.search-button")
                    Button("Bookmarks", systemImage: "bookmark", action: onOpenBookmarks)
                        .accessibilityIdentifier("epub-reader.bookmarks-button")
                }
                .navigationTitle("Navigate Book")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .accessibilityIdentifier("epub-reader.navigation")
        }
    }

    #if DEBUG
        #Preview("EPUB Reader Navigation") {
            EPUBReaderNavigationPanel(
                onOpenContents: {},
                onOpenSearch: {},
                onOpenBookmarks: {}
            )
        }
    #endif
#endif
