import SwiftUI

struct ComicReaderSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.artworkPalette) private var artworkPalette

    let readerMode: ReaderMode
    @Binding var pageOptions: ComicReaderOptions
    let onSetMode: (ReaderMode) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading Mode") {
                    Picker("Reading Mode", selection: readerModeBinding) {
                        Label("Regular", systemImage: "book.pages").tag(ReaderMode.paged)
                        Label("Webtoon", systemImage: "rectangle.stack").tag(ReaderMode.webtoon)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if readerMode == .paged {
                    Section("Page Layout") {
                        Picker("Page Layout", selection: $pageOptions.pageMode) {
                            Label("Automatic", systemImage: "book").tag(ComicPageMode.automatic)
                            Label("One Page", systemImage: "rectangle").tag(ComicPageMode.single)
                            Label("Two Pages", systemImage: "rectangle.split.2x1").tag(ComicPageMode.double)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()

                        if pageOptions.pageMode != .single {
                            Toggle("First Page Is Cover", isOn: $pageOptions.firstPageIsCover)
                        }
                    }

                    Section("Reading Direction") {
                        Picker("Reading Direction", selection: $pageOptions.readingDirection) {
                            Label("Automatic", systemImage: "arrow.left.and.right")
                                .tag(ComicReadingDirection.automatic)
                            Label("Left to Right", systemImage: "arrow.right")
                                .tag(ComicReadingDirection.leftToRight)
                            Label("Right to Left", systemImage: "arrow.left")
                                .tag(ComicReadingDirection.rightToLeft)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        .accessibilityIdentifier("comic-reader.settings.reading-direction")
                    }
                }
            }
            .prismediaScreenBackground(palette: artworkPalette)
            .formStyle(.grouped)
            .navigationTitle("Reader Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("comic-reader.settings.sheet")
    }

    private var readerModeBinding: Binding<ReaderMode> {
        Binding(
            get: { readerMode },
            set: { onSetMode($0) }
        )
    }
}

#if DEBUG
    #Preview("Comic Reader Settings") {
        @Previewable @State var options = ComicReaderOptions()
        ComicReaderSettingsSheet(
            readerMode: .paged,
            pageOptions: $options,
            onSetMode: { _ in }
        )
        .preferredColorScheme(.dark)
    }
#endif
