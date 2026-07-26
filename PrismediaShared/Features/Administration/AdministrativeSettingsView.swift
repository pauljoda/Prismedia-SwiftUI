import SwiftUI

struct AdministrativeSettingsView: View {
    @State private var catalog = AdministrativeSettingsCatalog(groups: [])
    @State private var cacheStatus: AdministrativeTranscodeCacheStatus?
    @State private var plugins: [AdministrativePlugin] = []
    @State private var isWorking = true
    @State private var message: String?
    private let service: any AdministrationServicing
    private let user: UserAccount
    private let hidesNsfw: Bool
    private let libraryService: any LibraryAdministrationServicing
    private let userService: any UserAdministrationServicing
    private let diagnosticsService: any DiagnosticsServicing
    private let backupService: any DatabaseBackupServicing
    private let onRestoreScheduled: () async -> Void

    init(
        service: any AdministrationServicing,
        user: UserAccount,
        hidesNsfw: Bool,
        libraryService: any LibraryAdministrationServicing,
        userService: any UserAdministrationServicing,
        diagnosticsService: any DiagnosticsServicing,
        backupService: any DatabaseBackupServicing,
        onRestoreScheduled: @escaping () async -> Void
    ) {
        self.service = service
        self.user = user
        self.hidesNsfw = hidesNsfw
        self.libraryService = libraryService
        self.userService = userService
        self.diagnosticsService = diagnosticsService
        self.backupService = backupService
        self.onRestoreScheduled = onRestoreScheduled
    }

    var body: some View {
        NavigationStack {
            settingsRootContent
                .prismediaScreenBackground()
                .overlay {
                    if isWorking && sections.isEmpty {
                        PrismediaLoadingView("Loading settings…")
                    } else if isWorking {
                        ProgressView("Loading settings…")
                    }
                }
                .navigationTitle("Settings")
                .navigationDestination(for: AdministrativeSettingsSection.self) { section in
                    AdministrativeSettingsDetailView(
                        section: currentSection(id: section.id) ?? section,
                        cacheStatus: cacheStatus,
                        plugins: plugins,
                        hidesNsfw: hidesNsfw,
                        blocklistService: service,
                        onSave: save,
                        onClearCache: clearCache,
                        onCreateBackup: createBackup
                    )
                }
                #if os(iOS) || os(macOS)
                    .navigationDestination(for: String.self) { destination in
                        dedicatedDestination(destination)
                    }
                #endif
                .refreshable { await load() }
                .alert("Settings", isPresented: messageIsPresented) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(message ?? "")
                }
        }
        .task { await load() }
        .accessibilityIdentifier("administration.settings")
    }

    @ViewBuilder
    private var settingsRootContent: some View {
        #if os(macOS)
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: 260, maximum: 380),
                            spacing: PrismediaSpacing.large
                        )
                    ],
                    spacing: PrismediaSpacing.large
                ) {
                    settingsCard(
                        title: "Entity Grids",
                        description: "Artwork, density, labels, and library display preferences.",
                        systemImage: "rectangle.grid.2x2",
                        accentID: "app-settings",
                        destination: "app-settings"
                    )
                    settingsCard(
                        title: "Watched Libraries",
                        description: "Library roots, scanners, ownership, and access.",
                        systemImage: "folder",
                        accentID: "libraries",
                        destination: "libraries"
                    )

                    if user.isAdmin {
                        settingsCard(
                            title: "Users",
                            description: "Accounts, roles, and library permissions.",
                            systemImage: "person.2",
                            accentID: "users",
                            destination: "users"
                        )
                    }

                    ForEach(sections) { section in
                        settingsCard(section)
                    }

                    if user.isAdmin {
                        settingsCard(
                            title: "Database Backups",
                            description: "Create, download, and restore database snapshots.",
                            systemImage: "archivebox",
                            accentID: "database-backups",
                            destination: "database-backups"
                        )
                        settingsCard(
                            title: "Diagnostics",
                            description: "Inspect server health and troubleshooting information.",
                            systemImage: "wrench.and.screwdriver",
                            accentID: "diagnostics",
                            destination: "diagnostics"
                        )
                    }
                }
                .padding(PrismediaSpacing.extraExtraLarge)
            }
        #else
            List {
                #if os(iOS) || os(macOS)
                    Section("App Settings") {
                        directoryLink("Entity Grids", "rectangle.grid.2x2", "app-settings")
                    }

                    Section {
                        directoryLink("Watched Libraries", "folder", "libraries")
                        if user.isAdmin { directoryLink("Users", "person.2", "users") }
                    }
                #endif

                Section {
                    ForEach(sections) { section in
                        NavigationLink(value: section) {
                            Label {
                                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                                    Text(section.title)
                                    Text(section.description).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: section.systemImageName)
                                    .foregroundStyle(settingsAccent(for: section.id))
                            }
                        }
                        .accessibilityIdentifier("administration.settings.section.\(section.id)")
                    }
                }

                #if os(iOS) || os(macOS)
                    if user.isAdmin {
                        Section {
                            directoryLink("Database Backups", "archivebox", "database-backups")
                            directoryLink("Diagnostics", "wrench.and.screwdriver", "diagnostics")
                        }
                    }
                #endif
            }
        #endif
    }

    #if os(macOS)
        private func settingsCard(_ section: AdministrativeSettingsSection) -> some View {
            NavigationLink(value: section) {
                settingsCardLabel(
                    title: section.title,
                    description: section.description,
                    systemImage: section.systemImageName,
                    accentID: section.id
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("administration.settings.section.\(section.id)")
        }

        private func settingsCard(
            title: String,
            description: String,
            systemImage: String,
            accentID: String,
            destination: String
        ) -> some View {
            NavigationLink(value: destination) {
                settingsCardLabel(
                    title: title,
                    description: description,
                    systemImage: systemImage,
                    accentID: accentID
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("administration.settings.section.\(destination)")
        }

        private func settingsCardLabel(
            title: String,
            description: String,
            systemImage: String,
            accentID: String
        ) -> some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(settingsAccent(for: accentID))
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .padding(PrismediaSpacing.large)
            .contentShape(.rect)
            .prismediaCard()
        }
    #endif

    private var sections: [AdministrativeSettingsSection] {
        AdministrativeSettingsSectionCatalog.sections(for: catalog)
    }

    private var messageIsPresented: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private func directoryLink(_ title: String, _ image: String, _ value: String) -> some View {
        NavigationLink(value: value) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: image)
                    .foregroundStyle(settingsAccent(for: value))
            }
        }
            .accessibilityIdentifier("administration.settings.section.\(value)")
    }

    private func settingsAccent(for id: String) -> Color {
        let index = orderedSettingsIDs.firstIndex(of: id) ?? 0
        return PrismediaColor.materialSpectrumColor(at: index)
    }

    private var orderedSettingsIDs: [String] {
        var ids = ["app-settings", "libraries"]
        if user.isAdmin { ids.append("users") }
        ids.append(contentsOf: sections.map(\.id))
        if user.isAdmin { ids.append(contentsOf: ["database-backups", "diagnostics"]) }
        return ids
    }

    #if os(iOS) || os(macOS)
        @ViewBuilder
        private func dedicatedDestination(_ destination: String) -> some View {
            switch destination {
            case "app-settings":
                AppSettingsView()
            case "libraries":
                AdministrativeLibrariesView(
                    user: user, service: libraryService, userService: user.isAdmin ? userService : nil)
            case "users":
                AdministrativeUsersView(currentUser: user, service: userService, libraryService: libraryService)
            case "database-backups":
                AdministrativeDatabaseBackupsView(service: backupService, onRestoreScheduled: onRestoreScheduled)
            case "diagnostics":
                AdministrativeDiagnosticsView(isAdministrator: user.isAdmin, service: diagnosticsService)
            default:
                ContentUnavailableView("Page Unavailable", systemImage: "rectangle.slash")
            }
        }
    #endif

    private func currentSection(id: String) -> AdministrativeSettingsSection? { sections.first { $0.id == id } }

    private func load() async {
        isWorking = true
        defer { isWorking = false }
        guard user.isAdmin else {
            catalog = AdministrativeSettingsCatalog(groups: [])
            cacheStatus = nil
            plugins = []
            return
        }
        do {
            async let loadedCatalog = service.settings()
            async let loadedCache = service.transcodeCacheStatus()
            catalog = try await loadedCatalog
            cacheStatus = try await loadedCache
            plugins = (try? await service.plugins()) ?? []
        } catch { message = error.localizedDescription }
    }

    private func save(setting: AdministrativeSetting, value: AdministrativeJSONValue) async
        -> AdministrativeSettingsSection?
    {
        do {
            _ = try await service.updateSetting(key: setting.key, value: value)
            catalog = try await service.settings()
            return currentSection(id: sectionID(containing: setting.groupKey))
        } catch {
            message = error.localizedDescription
            return nil
        }
    }

    private func sectionID(containing groupKey: String) -> String {
        sections.first { section in section.groups.contains { $0.key == groupKey } }?.id ?? groupKey
    }

    private func clearCache() async -> AdministrativeTranscodeCacheStatus? {
        do {
            let status = try await service.clearTranscodeCache()
            cacheStatus = status
            message = "Transcode cache cleared."
            return status
        } catch {
            message = error.localizedDescription
            return nil
        }
    }

    private func createBackup() async -> Bool {
        do {
            let backup = try await service.createDatabaseBackup()
            message = "Created \(backup.fileName)."
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }
}

#if DEBUG
    #Preview {
        AdministrativeSettingsView(
            service: AdministrativePreviewService(),
            user: PrismediaPreviewData.user,
            hidesNsfw: true,
            libraryService: Step3AdministrationPreviewService(),
            userService: Step3AdministrationPreviewService(),
            diagnosticsService: Step3AdministrationPreviewService(),
            backupService: Step3AdministrationPreviewService(),
            onRestoreScheduled: {}
        )
    }
#endif
