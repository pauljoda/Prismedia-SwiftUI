import SwiftUI

struct AccountView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    let user: UserAccount
    let service: any AccountServicing

    var body: some View {
        NavigationStack {
            Form {
                AccountProfileSection(user: user, service: service) {
                    await environment.verifyCurrentSession()
                }
                if user.allowNsfw {
                    Section("Visibility") {
                        Toggle(
                            "Allow NSFW Content",
                            isOn: Binding(
                                get: { environment.allowsNsfwContent },
                                set: environment.setAllowsNsfwContent
                            )
                        )
                    }
                }
                AccountPasswordSection(service: service) {}
                AccountSessionsSection(service: service) { await environment.signOut() }
                Section {
                    Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        Task { await environment.signOut() }
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("account")
    }
}

#if DEBUG
    #Preview("Account · Content") {
        PreviewShell(signedIn: true) {
            AccountView(user: PrismediaPreviewData.user, service: AccountPreviewService())
        }
    }

    #Preview("Account · Accessibility") {
        PreviewShell(signedIn: true) {
            AccountView(user: PrismediaPreviewData.user, service: AccountPreviewService())
                .environment(\.dynamicTypeSize, .accessibility3)
        }
    }
#endif
