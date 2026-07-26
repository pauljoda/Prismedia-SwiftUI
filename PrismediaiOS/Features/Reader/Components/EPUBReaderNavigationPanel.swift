#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct EPUBReaderNavigationPanel: View {
        @Environment(\.artworkPalette) private var artworkPalette

        var body: some View {
            List {
                NavigationLink(value: EPUBReaderSheet.contents) {
                    Label("Table of Contents", systemImage: "list.bullet.indent")
                }
                .accessibilityIdentifier("epub-reader.table-of-contents")

                NavigationLink(value: EPUBReaderSheet.search) {
                    Label("Search Book", systemImage: "magnifyingglass")
                }
                .accessibilityIdentifier("epub-reader.search-button")

                NavigationLink(value: EPUBReaderSheet.bookmarks) {
                    Label("Bookmarks", systemImage: "bookmark")
                }
                .accessibilityIdentifier("epub-reader.bookmarks-button")
            }
            .prismediaScreenBackground(palette: artworkPalette)
            .navigationTitle("Navigate Book")
            .accessibilityIdentifier("epub-reader.navigation")
        }
    }

    #if DEBUG
        #Preview("EPUB Reader Navigation") {
            NavigationStack {
                EPUBReaderNavigationPanel()
            }
        }
    #endif
#endif
