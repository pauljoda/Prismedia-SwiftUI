import SwiftUI

#if os(tvOS)
    struct TVAccountSettingsView: View {
        let user: UserAccount
        let onSignOut: () -> Void
        @State private var isConfirmingSignOut = false

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
                            action: { isConfirmingSignOut = true }
                        )
                        .accessibilityIdentifier("tv.account.sign-out")
                    }
                }
            }
            .navigationTitle(TVSettingsDestination.account.title)
            .alert("Sign Out?", isPresented: $isConfirmingSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive, action: onSignOut)
            } message: {
                Text("You’ll return to the Prismedia sign-in screen on this Apple TV.")
            }
        }
    }

    #if DEBUG
        #Preview("TV Account Settings") {
            NavigationStack {
                TVAccountSettingsView(
                    user: PrismediaPreviewData.user,
                    onSignOut: {}
                )
            }
        }
    #endif
#endif
