#if os(iOS) || os(macOS)
    import SwiftUI

    struct ComicReaderToolbar: ToolbarContent {
        @Binding var pageOptions: ComicReaderOptions
        @Binding var isSettingsPresented: Bool

        let readerMode: ReaderMode
        let onClose: () -> Void
        let onSetMode: (ReaderMode) -> Void
        let onOpenSettings: () -> Void

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            ToolbarItem(placement: .cancellationAction) {
                ReaderCloseButton(accessibilityPrefix: "comic-reader", action: onClose)
            }

            ToolbarItem(placement: .primaryAction) {
                settingsControl
            }
        }

        @ViewBuilder
        private var settingsControl: some View {
            #if os(iOS)
                settingsButton
                    .popover(isPresented: $isSettingsPresented, arrowEdge: .top) {
                        settingsContent
                            .presentationCompactAdaptation(.popover)
                    }
            #else
                settingsButton
                    .popover(isPresented: $isSettingsPresented, arrowEdge: .top) {
                        settingsContent
                    }
            #endif
        }

        private var settingsButton: some View {
            Button("Reader settings", systemImage: "ellipsis", action: onOpenSettings)
                .accessibilityIdentifier("comic-reader.settings")
        }

        private var settingsContent: some View {
            ComicReaderSettingsPopover(
                readerMode: readerMode,
                pageOptions: $pageOptions,
                isPresented: $isSettingsPresented,
                onSetMode: onSetMode
            )
        }
    }

    #if DEBUG
        #Preview("Comic Reader Toolbar") {
            @Previewable @State var options = ComicReaderOptions()
            @Previewable @State var isSettingsPresented = false

            NavigationStack {
                Color.black
                    .ignoresSafeArea()
                    .toolbar {
                        ComicReaderToolbar(
                            pageOptions: $options,
                            isSettingsPresented: $isSettingsPresented,
                            readerMode: .paged,
                            onClose: {},
                            onSetMode: { _ in },
                            onOpenSettings: { isSettingsPresented = true }
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
