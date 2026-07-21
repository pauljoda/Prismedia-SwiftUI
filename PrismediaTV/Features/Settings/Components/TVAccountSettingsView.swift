import SwiftUI

#if os(tvOS)
    struct TVAccountSettingsView: View {
        let user: UserAccount
        let onRequestSignOut: () -> Void

        var body: some View {
            TVSettingsSplitLayout(
                title: TVSettingsDestination.account.title,
                description: TVSettingsDestination.account.description
            ) {
                Form {
                    Section("Profile") {
                        LabeledContent("Name", value: user.displayName)
                        LabeledContent("Username", value: "@\(user.username)")
                        LabeledContent("Role", value: user.role.rawValue.capitalized)
                    }

                    Section {
                        Button(
                            "Sign Out",
                            systemImage: "rectangle.portrait.and.arrow.right",
                            role: .destructive,
                            action: onRequestSignOut
                        )
                        .accessibilityIdentifier("tv.account.sign-out")
                    }
                }
            }
            .navigationTitle(TVSettingsDestination.account.title)
        }
    }

    #if DEBUG
        #Preview("TV Account Settings") {
            NavigationStack {
                TVAccountSettingsView(
                    user: PrismediaPreviewData.user,
                    onRequestSignOut: {}
                )
            }
        }
    #endif
#endif
