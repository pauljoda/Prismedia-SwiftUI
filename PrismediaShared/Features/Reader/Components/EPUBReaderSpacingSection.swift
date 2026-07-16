#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReaderSpacingSection: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Section {
                Stepper(value: $preferences.lineHeight, in: 1.2...2, step: 0.1) {
                    LabeledContent(
                        "Line Spacing",
                        value: preferences.lineHeight,
                        format: .number.precision(.fractionLength(1))
                    )
                }

                Stepper(value: $preferences.letterSpacing, in: 0...0.3, step: 0.05) {
                    LabeledContent("Letter Spacing", value: preferences.letterSpacing, format: .percent)
                }

                Stepper(value: $preferences.wordSpacing, in: 0...0.5, step: 0.05) {
                    LabeledContent("Word Spacing", value: preferences.wordSpacing, format: .percent)
                }

                Stepper(value: $preferences.paragraphSpacing, in: 0...1.5, step: 0.1) {
                    LabeledContent("Paragraph Spacing", value: preferences.paragraphSpacing, format: .percent)
                }

                Stepper(value: $preferences.paragraphIndent, in: 0...2, step: 0.1) {
                    LabeledContent("Paragraph Indent", value: preferences.paragraphIndent, format: .percent)
                }
            } header: {
                Text("Spacing")
            } footer: {
                Text(
                    "Use paragraph spacing for a modern layout, indentation for a traditional book layout, or combine them to taste."
                )
            }
            .disabled(preferences.usesPublisherStyles)
        }
    }

    #if DEBUG
        #Preview("Reader Spacing") {
            @Previewable @State var preferences = EPUBReaderPreferences()
            Form { EPUBReaderSpacingSection(preferences: $preferences) }
        }
    #endif
#endif
