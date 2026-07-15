#if os(iOS) || os(macOS)
    import SwiftUI

    struct ComicReaderToolbar: ToolbarContent {
        let onClose: () -> Void
        let onOpenSettings: () -> Void

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            ToolbarItem(placement: .cancellationAction) {
                ReaderCloseButton(accessibilityPrefix: "comic-reader", action: onClose)
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Reader settings", systemImage: "ellipsis", action: onOpenSettings)
                    .accessibilityIdentifier("comic-reader.settings")
            }
        }
    }

    #if DEBUG
        #Preview("Comic Reader Toolbar") {
            NavigationStack {
                Color.black
                    .ignoresSafeArea()
                    .toolbar {
                        ComicReaderToolbar(
                            onClose: {},
                            onOpenSettings: {}
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
