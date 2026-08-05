#if os(iOS) || os(macOS)
    import SwiftUI

    struct ComicReaderToolbar: ToolbarContent {
        let showsCloseButton: Bool
        let onClose: () -> Void
        let onOpenSettings: () -> Void

        init(
            showsCloseButton: Bool = true,
            onClose: @escaping () -> Void,
            onOpenSettings: @escaping () -> Void
        ) {
            self.showsCloseButton = showsCloseButton
            self.onClose = onClose
            self.onOpenSettings = onOpenSettings
        }

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            if showsCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    ReaderCloseButton(accessibilityPrefix: "comic-reader", action: onClose)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Reader settings", systemImage: "ellipsis", action: onOpenSettings)
                    .prismediaToolbarActionLabelStyle()
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
