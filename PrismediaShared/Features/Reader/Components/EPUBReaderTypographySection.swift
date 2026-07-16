#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReaderTypographySection: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Section {
                Toggle("Use Publisher Formatting", isOn: $preferences.usesPublisherStyles)

                Picker("Typeface", selection: $preferences.fontFamily) {
                    ForEach(EPUBReaderFontFamily.allCases, id: \.self) { family in
                        Text(title(for: family)).tag(family)
                    }
                }

                Stepper(value: $preferences.fontScale, in: 0.8...2, step: 0.1) {
                    LabeledContent("Text Size", value: preferences.fontScale, format: .percent)
                }

                Stepper(value: $preferences.fontWeight, in: 0.75...1.5, step: 0.05) {
                    LabeledContent("Text Weight", value: preferences.fontWeight, format: .percent)
                }

                Toggle("Normalize Text Styles", isOn: $preferences.textNormalizationEnabled)
            } header: {
                Text("Typography")
            } footer: {
                if preferences.usesPublisherStyles {
                    Text(
                        "Publisher formatting can override spacing and paragraph controls. Turn it off for full control."
                    )
                } else {
                    Text("Normalization applies the chosen weight consistently to headings and body text.")
                }
            }
        }

        private func title(for family: EPUBReaderFontFamily) -> String {
            switch family {
            case .publisher: "Publisher Typeface"
            case .serif: "Book Serif"
            case .literary: "Literary Serif"
            case .sansSerif: "Humanist Sans"
            case .accessible: "Accessible"
            case .openDyslexic: "OpenDyslexic"
            case .monospaced: "Duospace"
            }
        }
    }

    #if DEBUG
        #Preview("Reader Typography") {
            @Previewable @State var preferences = EPUBReadingProfile.accessible.preferences
            Form { EPUBReaderTypographySection(preferences: $preferences) }
        }
    #endif
#endif
