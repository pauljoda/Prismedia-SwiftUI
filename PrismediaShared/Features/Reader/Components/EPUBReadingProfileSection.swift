#if os(iOS) || os(macOS)
    import SwiftUI

    struct EPUBReadingProfileSection: View {
        @Binding var preferences: EPUBReaderPreferences

        var body: some View {
            Section {
                Picker("Reading Profile", selection: profileBinding) {
                    ForEach(EPUBReadingProfile.selectableCases, id: \.self) { profile in
                        Text(title(for: profile)).tag(profile)
                    }
                    if preferences.matchingProfile == .custom {
                        Text(title(for: .custom)).tag(EPUBReadingProfile.custom)
                    }
                }
            } header: {
                Text("Profile")
            } footer: {
                Text(
                    "Profiles are starting points. Changing any option creates a custom profile, saved for every book.")
            }
        }

        private var profileBinding: Binding<EPUBReadingProfile> {
            Binding(
                get: { preferences.matchingProfile },
                set: { profile in
                    guard profile != .custom else { return }
                    preferences = profile.preferences
                }
            )
        }

        private func title(for profile: EPUBReadingProfile) -> String {
            switch profile {
            case .paper: "Paper"
            case .comfortable: "Comfortable"
            case .focus: "Focus"
            case .accessible: "Accessibility"
            case .night: "Night"
            case .original: "Publisher Original"
            case .custom: "Custom"
            }
        }
    }

    #if DEBUG
        #Preview("Reading Profile") {
            @Previewable @State var preferences = EPUBReaderPreferences()
            Form { EPUBReadingProfileSection(preferences: $preferences) }
        }
    #endif
#endif
