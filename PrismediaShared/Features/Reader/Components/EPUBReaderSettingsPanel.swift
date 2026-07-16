#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReaderSettingsPanel: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Form {
                EPUBReadingProfileSection(preferences: $preferences)
                EPUBReaderAppearanceSection(preferences: $preferences)
                EPUBReaderTypographySection(preferences: $preferences)
                EPUBReaderSpacingSection(preferences: $preferences)
                EPUBReaderLayoutSection(preferences: $preferences)
                EPUBReaderFocusSection(preferences: $preferences)

                Section {
                    Button("Restore Reader Defaults") {
                        preferences = EPUBReaderPreferences()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Reader Settings")
            .accessibilityIdentifier("epub-reader.settings")
        }
    }

    #if DEBUG
        #Preview("EPUB Settings · Paper") {
            @Previewable @State var preferences = EPUBReaderPreferences()
            NavigationStack {
                EPUBReaderSettingsPanel(preferences: $preferences)
            }
        }

        #Preview("EPUB Settings · Accessibility") {
            @Previewable @State var preferences = EPUBReadingProfile.accessible.preferences
            NavigationStack {
                EPUBReaderSettingsPanel(preferences: $preferences)
            }
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
