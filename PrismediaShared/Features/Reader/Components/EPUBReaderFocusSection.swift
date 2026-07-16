#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReaderFocusSection: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Section {
                Toggle("Progressive Paragraph Focus", isOn: $preferences.scrollFocusEnabled)

                if preferences.scrollFocusEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent(
                            "Fade Strength",
                            value: preferences.scrollFocusStrength,
                            format: .percent
                        )
                        Slider(
                            value: $preferences.scrollFocusStrength,
                            in: 0.25...0.8,
                            step: 0.05
                        ) {
                            Text("Fade Strength")
                        } minimumValueLabel: {
                            Image(systemName: "circle.lefthalf.filled")
                                .accessibilityLabel("Gentle")
                        } maximumValueLabel: {
                            Image(systemName: "circle.fill")
                                .accessibilityLabel("Strong")
                        }
                    }
                }

                Toggle("Reading Guide", isOn: $preferences.readingGuideEnabled)
            } header: {
                Text("Reading Focus")
            } footer: {
                if preferences.flow == .scrolled {
                    Text(
                        "Paragraph focus keeps the text nearest the center fully visible and progressively fades surrounding passages. The guide settles beneath the center line after scrolling stops."
                    )
                } else {
                    Text("Reading focus is available when Flow is set to Scroll.")
                }
            }
            .disabled(preferences.flow != .scrolled)
        }
    }

    #if DEBUG
        #Preview("Reader Focus") {
            @Previewable @State var preferences = EPUBReadingProfile.focus.preferences
            Form { EPUBReaderFocusSection(preferences: $preferences) }
        }
    #endif
#endif
