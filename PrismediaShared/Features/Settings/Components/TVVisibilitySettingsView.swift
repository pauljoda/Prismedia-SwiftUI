import SwiftUI

#if os(tvOS)
    struct TVVisibilitySettingsView: View {
        @Binding var allowsNsfwContent: Bool

        var body: some View {
            TVSettingsSplitLayout(
                title: TVSettingsDestination.visibility.title,
                description: TVSettingsDestination.visibility.description
            ) {
                Form {
                    Section {
                        Toggle("Allow NSFW Content", isOn: $allowsNsfwContent)
                            .accessibilityIdentifier("tv.settings.allowNsfw")
                    } footer: {
                        Text("This only changes what is shown for the active account on this Apple TV.")
                    }
                }
            }
            .navigationTitle(TVSettingsDestination.visibility.title)
        }
    }

    #if DEBUG
        #Preview("TV Visibility Settings") {
            @Previewable @State var allowsNsfwContent = false
            NavigationStack {
                TVVisibilitySettingsView(allowsNsfwContent: $allowsNsfwContent)
            }
        }
    #endif
#endif
