import SwiftUI

struct AdministrativeDatabaseBackupsView: View {
    @State private var catalog = AdministrativeCollectionLoadState<AdministrativeDatabaseBackupList>()
    @State private var isCreating = false
    @State private var creationMessage: String?
    @State private var actionError: String?
    let service: any DatabaseBackupServicing
    let onRestoreScheduled: () async -> Void

    var body: some View {
        Form {
            if let error = catalog.errorMessage {
                PrismediaRetryView(
                    title: "Couldn't Load Backups", message: error,
                    retry: { Task { await load() } })
            }
            if isCreating {
                Section { ProgressView("Creating backup…") }
            } else if let creationMessage {
                Section { Text(creationMessage) }
            }
            AdministrativeDatabaseBackupSection(
                isWorking: isCreating || !catalog.isReady, onCreate: create)
            if let state = catalog.items.first {
                Section("Backups") {
                    if state.backups.isEmpty {
                        ContentUnavailableView(
                            "No Backups", systemImage: "archivebox",
                            description: Text("Create a backup or wait for the next scheduled backup."))
                    }
                    ForEach(state.backups) { backup in
                        NavigationLink(value: backup) {
                            AdministrativeDatabaseBackupRow(backup: backup)
                        }
                    }
                }
                Section("Schedule and Storage") {
                    LabeledContent("Next automatic backup") {
                        Text(state.nextAutomaticBackupAt?.formatted(.dateTime) ?? "Not scheduled")
                    }
                    LabeledContent("Automatic retention", value: "\(state.automaticRetentionDays) days")
                    AdministrativeDetailsDisclosure("Backup directory") {
                        Text(state.backupDirectory).font(.body.monospaced()).prismediaTextSelection()
                    }
                }
            }
        }
        .prismediaSettingsForm()
        .overlay {
            if catalog.isLoading && catalog.items.isEmpty {
                PrismediaLoadingView("Loading backups…")
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Database Backups")
        .toolbar {
            PrismediaToolbarActionButton("Refresh Backups", systemImage: "arrow.clockwise") {
                Task { await load() }
            }
            .disabled(catalog.isLoading || isCreating)
        }
        .navigationDestination(for: AdministrativeDatabaseBackup.self) { backup in
            AdministrativeBackupDetailView(
                backup: backup, service: service, onRestoreScheduled: onRestoreScheduled)
        }
        .task { await load() }
        .refreshable { await PrismediaRefreshAction.perform { await load() } }
        .alert(
            "Couldn't Create Backup",
            isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
        .accessibilityIdentifier("administration.settings.database-backups")
    }

    private func load() async {
        guard !isCreating else { return }
        await refresh()
    }

    private func refresh() async {
        let request = catalog.begin()
        do {
            let loaded = try await service.backups()
            catalog.succeed([loaded], request: request, isCancelled: Task.isCancelled)
        } catch {
            catalog.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    private func create() async {
        guard !isCreating, catalog.isReady else { return }
        isCreating = true
        creationMessage = nil
        actionError = nil
        defer { isCreating = false }
        do {
            let backup = try await service.create()
            creationMessage = backup.isRestorable ? "Backup created." : "Backup requested. Check its status below."
            await refresh()
        } catch {
            actionError = error.localizedDescription
        }
    }
}

#if DEBUG
    #Preview("Backups · Content") {
        NavigationStack {
            AdministrativeDatabaseBackupsView(service: Step3AdministrationPreviewService(), onRestoreScheduled: {})
        }
    }
#endif
