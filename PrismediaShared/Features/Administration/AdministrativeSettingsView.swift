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
            List {
                #if os(iOS) || os(macOS)
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
                                Image(systemName: section.systemImageName).foregroundStyle(.tint)
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

    private var sections: [AdministrativeSettingsSection] {
        AdministrativeSettingsSectionCatalog.sections(for: catalog)
    }

    private var messageIsPresented: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private func directoryLink(_ title: String, _ image: String, _ value: String) -> some View {
        NavigationLink(value: value) { Label(title, systemImage: image) }
            .accessibilityIdentifier("administration.settings.section.\(value)")
    }

    #if os(iOS) || os(macOS)
        @ViewBuilder
        private func dedicatedDestination(_ destination: String) -> some View {
            switch destination {
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
