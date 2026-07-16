#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReaderLayoutSection: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Section("Layout") {
                Picker("Flow", selection: $preferences.flow) {
                    Label("Paged", systemImage: "book.pages").tag(ReaderMode.paged)
                    Label("Scroll", systemImage: "scroll").tag(ReaderMode.scrolled)
                }
                .pickerStyle(.segmented)

                Picker("Columns", selection: $preferences.columnCount) {
                    Text("Automatic").tag(EPUBReaderColumnCount.automatic)
                    Text("One").tag(EPUBReaderColumnCount.one)
                    Text("Two").tag(EPUBReaderColumnCount.two)
                }
                .disabled(preferences.flow == .scrolled)

                Stepper(value: $preferences.pageMargins, in: 0.5...2.5, step: 0.1) {
                    LabeledContent(
                        "Margins",
                        value: preferences.pageMargins,
                        format: .number.precision(.fractionLength(1))
                    )
                }

                Picker("Alignment", selection: $preferences.textAlignment) {
                    Text("Automatic").tag(EPUBReaderTextAlignment.automatic)
                    Text("Leading").tag(EPUBReaderTextAlignment.leading)
                    Text("Justified").tag(EPUBReaderTextAlignment.justified)
                }
                .disabled(preferences.usesPublisherStyles)

                Toggle("Hyphenation", isOn: $preferences.hyphenationEnabled)
                    .disabled(preferences.usesPublisherStyles)
            }
        }
    }

    #if DEBUG
        #Preview("Reader Layout") {
            @Previewable @State var preferences = EPUBReaderPreferences()
            Form { EPUBReaderLayoutSection(preferences: $preferences) }
        }
    #endif
#endif
