import SwiftUI

#if os(tvOS)
    struct TVSettingsView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        let user: UserAccount
        let playbackPreferences: VideoPlaybackPreferences
        let administrationService: any AdministrationServicing
        let onSignOut: () -> Void

        @State private var catalog = AdministrativeSettingsCatalog(groups: [])
        @State private var plugins: [AdministrativePlugin] = []
        @State private var isLoadingServerSettings = false
        @State private var message: String?
        @State private var isConfirmingSignOut = false

        var body: some View {
            TVSettingsDirectoryView(
                user: user,
                serverSections: serverSections,
                isLoadingServerSettings: isLoadingServerSettings
            )
            .navigationTitle("Settings")
            .navigationDestination(for: TVSettingsDestination.self) { destination in
                destinationView(destination)
            }
            .navigationDestination(for: AdministrativeSettingsSection.self) { section in
                TVSettingsSplitLayout(
                    title: section.title,
                    description: section.description
                ) {
                    AdministrativeSettingsDetailView(
                        section: currentSection(id: section.id) ?? section,
                        cacheStatus: nil,
                        plugins: plugins,
                        hidesNsfw: !environment.allowsNsfwContent,
                        onSave: save,
                        onClearCache: { nil },
                        onCreateBackup: { false }
                    )
                }
            }
            .task { await loadServerSettings() }
            .refreshable { await loadServerSettings() }
            .alert("Sign Out?", isPresented: $isConfirmingSignOut) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive, action: onSignOut)
            } message: {
                Text("You’ll return to the Prismedia sign-in screen on this Apple TV.")
            }
            .alert("Settings", isPresented: messageIsPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .accessibilityIdentifier("tv.settings")
        }

        @ViewBuilder
        private func destinationView(_ destination: TVSettingsDestination) -> some View {
            switch destination {
            case .player:
                TVPlayerSettingsView(playbackPreferences: playbackPreferences)
            case .visibility:
                TVVisibilitySettingsView(
                    allowsNsfwContent: Binding(
                        get: { environment.allowsNsfwContent },
                        set: { environment.setAllowsNsfwContent($0) }
                    )
                )
            case .account:
                TVAccountSettingsView(user: user) {
                    isConfirmingSignOut = true
                }
            }
        }

        private var serverSections: [AdministrativeSettingsSection] {
            AdministrativeSettingsSectionCatalog.sections(for: catalog)
                .filter { $0.id == "playback" || $0.id == "subtitles" }
        }

        private var messageIsPresented: Binding<Bool> {
            Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )
        }

        private func currentSection(id: String) -> AdministrativeSettingsSection? {
            serverSections.first { $0.id == id }
        }

        private func loadServerSettings() async {
            guard user.isAdmin else { return }
            isLoadingServerSettings = true
            defer { isLoadingServerSettings = false }
            do {
                async let loadedCatalog = administrationService.settings()
                async let loadedPlugins = try? administrationService.plugins()
                catalog = try await loadedCatalog
                plugins = await loadedPlugins ?? []
            } catch {
                message = error.localizedDescription
            }
        }

        private func save(
            setting: AdministrativeSetting,
            value: AdministrativeJSONValue
        ) async -> AdministrativeSettingsSection? {
            do {
                _ = try await administrationService.updateSetting(key: setting.key, value: value)
                catalog = try await administrationService.settings()
                return currentSection(id: sectionID(containing: setting.groupKey))
            } catch {
                message = error.localizedDescription
                return nil
            }
        }

        private func sectionID(containing groupKey: String) -> String {
            serverSections.first { section in
                section.groups.contains { $0.key == groupKey }
            }?.id ?? groupKey
        }
    }

    #if DEBUG
        #Preview("TV Settings") {
            PreviewShell {
                NavigationStack {
                    TVSettingsView(
                        user: PrismediaPreviewData.user,
                        playbackPreferences: VideoPlaybackPreferences(),
                        administrationService: AdministrativePreviewService(),
                        onSignOut: {}
                    )
                }
            }
        }
    #endif
#endif
