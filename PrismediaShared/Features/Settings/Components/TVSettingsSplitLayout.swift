import SwiftUI

#if os(tvOS)
    struct TVSettingsSplitLayout<Content: View>: View {
        let title: String
        let description: String
        @ViewBuilder let content: () -> Content

        var body: some View {
            HStack(spacing: PrismediaSpacing.screen) {
                TVSettingsIdentityPanel(title: title, description: description)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, PrismediaSpacing.screen)
            .prismediaScreenBackground()
        }
    }

    #if DEBUG
        #Preview("TV Settings Split Layout") {
            TVSettingsSplitLayout(
                title: "Settings",
                description: "Choose how Prismedia behaves on this Apple TV."
            ) {
                Form {
                    Label("Player", systemImage: "play.rectangle")
                    Label("Account", systemImage: "person.crop.circle")
                }
            }
        }
    #endif
#endif
