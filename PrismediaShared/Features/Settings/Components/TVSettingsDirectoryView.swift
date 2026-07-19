import SwiftUI

#if os(tvOS)
    struct TVSettingsDirectoryView: View {
        let user: UserAccount
        let serverSections: [AdministrativeSettingsSection]
        let isLoadingServerSettings: Bool

        var body: some View {
            TVSettingsSplitLayout(
                title: "Settings",
                description: "Choose how Prismedia plays, presents, and connects on this Apple TV."
            ) {
                Form {
                    Section("Playback") {
                        NavigationLink(value: TVSettingsDestination.player) {
                            TVSettingsNavigationLabel(
                                title: TVSettingsDestination.player.title,
                                description: TVSettingsDestination.player.description,
                                systemImageName: TVSettingsDestination.player.systemImageName
                            )
                        }
                        .accessibilityIdentifier("tv.settings.player")

                        if user.isAdmin {
                            ForEach(serverSections) { section in
                                NavigationLink(value: section) {
                                    TVSettingsNavigationLabel(
                                        title: section.title,
                                        description: section.description,
                                        systemImageName: section.systemImageName
                                    )
                                }
                                .accessibilityIdentifier("tv.settings.server.\(section.id)")
                            }

                            if isLoadingServerSettings {
                                HStack {
                                    ProgressView()
                                    Text("Loading server settings…")
                                }
                            } else if serverSections.isEmpty {
                                Label("Server settings are unavailable", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(PrismediaColor.textSecondary)
                            }
                        }
                    }

                    if user.allowNsfw {
                        Section("Library") {
                            NavigationLink(value: TVSettingsDestination.visibility) {
                                TVSettingsNavigationLabel(
                                    title: TVSettingsDestination.visibility.title,
                                    description: TVSettingsDestination.visibility.description,
                                    systemImageName: TVSettingsDestination.visibility.systemImageName
                                )
                            }
                            .accessibilityIdentifier("tv.settings.visibility")
                        }
                    }

                    Section("Prismedia") {
                        NavigationLink(value: TVSettingsDestination.account) {
                            TVSettingsNavigationLabel(
                                title: TVSettingsDestination.account.title,
                                description: TVSettingsDestination.account.description,
                                systemImageName: TVSettingsDestination.account.systemImageName
                            )
                        }
                        .accessibilityIdentifier("tv.settings.account")
                    }
                }
            }
        }
    }

    #if DEBUG
        #Preview("TV Settings Directory") {
            NavigationStack {
                TVSettingsDirectoryView(
                    user: PrismediaPreviewData.user,
                    serverSections: [],
                    isLoadingServerSettings: false
                )
            }
        }
    #endif
#endif
