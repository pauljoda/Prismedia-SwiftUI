import SwiftUI

struct ComicReaderSettingsPopover: View {
    let readerMode: ReaderMode
    @Binding var pageOptions: ComicReaderOptions
    @Binding var isPresented: Bool
    let onSetMode: (ReaderMode) -> Void

    var body: some View {
        #if os(tvOS)
            settingsForm
        #else
            settingsForm
                .scrollContentBackground(.hidden)
        #endif
    }

    private var settingsForm: some View {
        Form {
            Section("Reading Mode") {
                Picker(
                    "Reading Mode",
                    selection: Binding(
                        get: { readerMode },
                        set: { mode in
                            onSetMode(mode)
                            isPresented = false
                        }
                    )
                ) {
                    Label("Regular", systemImage: "book.pages").tag(ReaderMode.paged)
                    Label("Webtoon", systemImage: "rectangle.stack").tag(ReaderMode.webtoon)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            if readerMode == .paged {
                Section("Page Layout") {
                    Picker(
                        "Page Layout",
                        selection: Binding(
                            get: { pageOptions.pageMode },
                            set: { pageMode in
                                pageOptions.pageMode = pageMode
                                isPresented = false
                            }
                        )
                    ) {
                        Label("One Page", systemImage: "rectangle").tag(ComicPageMode.single)
                        Label("Two Pages", systemImage: "rectangle.split.2x1").tag(ComicPageMode.double)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    if pageOptions.pageMode == .double {
                        Toggle("First Page Is Cover", isOn: $pageOptions.firstPageIsCover)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 280, minHeight: 260)
        .accessibilityIdentifier("comic-reader.settings.popover")
    }
}

#if DEBUG
    #Preview("Comic Reader Settings") {
        ComicReaderSettingsPopover(
            readerMode: .paged,
            pageOptions: .constant(ComicReaderOptions()),
            isPresented: .constant(true),
            onSetMode: { _ in }
        )
    }
#endif
