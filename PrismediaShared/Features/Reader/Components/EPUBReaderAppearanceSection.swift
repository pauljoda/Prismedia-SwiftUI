#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReaderAppearanceSection: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Section("Page Appearance") {
                Picker("Theme", selection: $preferences.theme) {
                    ForEach(EPUBReaderTheme.allCases, id: \.self) { theme in
                        Text(title(for: theme)).tag(theme)
                    }
                }
            }
        }

        private func title(for theme: EPUBReaderTheme) -> String {
            switch theme {
            case .system: "Automatic"
            case .paper: "Paper"
            case .light: "White"
            case .sepia: "Sepia"
            case .gray: "Soft Gray"
            case .dark: "Dark"
            }
        }
    }

    #if DEBUG
        #Preview("Reader Appearance") {
            @Previewable @State var preferences = EPUBReaderPreferences()
            Form { EPUBReaderAppearanceSection(preferences: $preferences) }
        }
    #endif
#endif
