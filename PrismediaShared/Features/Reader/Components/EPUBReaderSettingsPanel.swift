#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReaderSettingsPanel: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Form {
                Section("Reading") {
                    Picker("Flow", selection: $preferences.flow) {
                        Label("Paged", systemImage: "book.pages").tag(ReaderMode.paged)
                        Label("Scroll", systemImage: "scroll").tag(ReaderMode.scrolled)
                    }
                    .pickerStyle(.segmented)

                    Picker("Theme", selection: $preferences.theme) {
                        Text("System").tag(EPUBReaderTheme.system)
                        Text("Light").tag(EPUBReaderTheme.light)
                        Text("Sepia").tag(EPUBReaderTheme.sepia)
                        Text("Dark").tag(EPUBReaderTheme.dark)
                    }
                }

                Section("Typography") {
                    Picker("Typeface", selection: $preferences.fontFamily) {
                        Text("Publisher").tag(EPUBReaderFontFamily.publisher)
                        Text("Serif").tag(EPUBReaderFontFamily.serif)
                        Text("Sans Serif").tag(EPUBReaderFontFamily.sansSerif)
                    }

                    Stepper(value: $preferences.fontScale, in: 0.8...2, step: 0.1) {
                        LabeledContent("Text Size", value: preferences.fontScale, format: .percent)
                    }
                    Stepper(value: $preferences.lineHeight, in: 1.2...2, step: 0.1) {
                        LabeledContent(
                            "Line Spacing", value: preferences.lineHeight,
                            format: .number.precision(.fractionLength(1)))
                    }
                    Stepper(value: $preferences.pageMargins, in: 0.5...2, step: 0.1) {
                        LabeledContent(
                            "Margins", value: preferences.pageMargins, format: .number.precision(.fractionLength(1))
                        )
                    }
                }

                Section {
                    Button("Restore Reader Defaults") {
                        preferences = EPUBReaderPreferences()
                    }
                }
            }
            .navigationTitle("Reader Settings")
            .accessibilityIdentifier("epub-reader.settings")
        }
    }

    #if DEBUG
        #Preview("EPUB Settings") {
            @Previewable @State var preferences = EPUBReaderPreferences()
            NavigationStack {
                EPUBReaderSettingsPanel(preferences: $preferences)
            }
        }
    #endif
#endif
