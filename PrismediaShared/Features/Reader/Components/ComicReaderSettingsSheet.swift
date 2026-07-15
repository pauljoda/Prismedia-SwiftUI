import SwiftUI

struct ComicReaderSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

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
            .navigationTitle("Reader Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
