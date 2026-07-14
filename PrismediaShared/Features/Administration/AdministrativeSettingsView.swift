import SwiftUI

struct AdministrativeSettingsView: View {
    @State private var catalog = AdministrativeSettingsCatalog(groups: [])
    @State private var cacheStatus: AdministrativeTranscodeCacheStatus?
    @State private var isWorking = true
    @State private var message: String?
    private let service: any AdministrationServicing

    init(service: any AdministrationServicing) { self.service = service }

    var body: some View {
        NavigationStack {
            List(sections) { section in
                NavigationLink(value: section) {
                    Label {
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Text(section.title)
                            Text(section.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: section.systemImageName)
                            .foregroundStyle(.tint)
                    }
                }
                .accessibilityIdentifier("administration.settings.section.\(section.id)")
            }
            .prismediaScreenBackground()
            .overlay {
                if isWorking && sections.isEmpty {
                    PrismediaLoadingView("Loading settings…")
                } else if isWorking {
                    ProgressView("Loading settings…")
                } else if sections.isEmpty {
                    ContentUnavailableView(
                        "No Settings Available",
                        systemImage: "gearshape",
                        description: Text("The server did not return any administrative settings.")
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: AdministrativeSettingsSection.self) { section in
                AdministrativeSettingsDetailView(
                    section: currentSection(id: section.id) ?? section,
                    cacheStatus: cacheStatus,
                    onSave: save,
                    onClearCache: clearCache,
                    onCreateBackup: createBackup
                )
            }
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
        Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )
    }

    private func currentSection(id: String) -> AdministrativeSettingsSection? {
        sections.first { $0.id == id }
    }

    private func load() async {
        isWorking = true
        defer { isWorking = false }
        do {
            async let loadedCatalog = service.settings()
            async let loadedCache = service.transcodeCacheStatus()
            catalog = try await loadedCatalog
            cacheStatus = try await loadedCache
        } catch {
            message = error.localizedDescription
        }
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
    #Preview { AdministrativeSettingsView(service: AdministrativePreviewService()) }
#endif
