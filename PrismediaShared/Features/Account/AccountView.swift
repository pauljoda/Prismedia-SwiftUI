import SwiftUI

struct AccountView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    let user: UserAccount
    let service: any AccountServicing
    let playbackPreferences: VideoPlaybackPreferences

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
                                set: { environment.setAllowsNsfwContent($0) }
                            )
                        )
                    }
                }
                VideoPlaybackEngineSettingsSection(
                    playbackPreferences: playbackPreferences
                )
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
            AccountView(
                user: PrismediaPreviewData.user,
                service: AccountPreviewService(),
                playbackPreferences: VideoPlaybackPreferences(
                    store: InMemoryVideoPlaybackEnginePreferenceStore()
                )
            )
        }
    }

    #Preview("Account · Accessibility") {
        PreviewShell(signedIn: true) {
            AccountView(
                user: PrismediaPreviewData.user,
                service: AccountPreviewService(),
                playbackPreferences: VideoPlaybackPreferences(
                    store: InMemoryVideoPlaybackEnginePreferenceStore()
                )
            )
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    }
#endif
