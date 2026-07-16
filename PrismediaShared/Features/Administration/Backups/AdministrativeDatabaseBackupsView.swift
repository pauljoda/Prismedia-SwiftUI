import SwiftUI

struct AdministrativeDatabaseBackupsView: View {
    @State private var state: AdministrativeDatabaseBackupList?
    @State private var isLoading = true
    @State private var isWorking = false
    @State private var selectedBackupID: UUID?
    @State private var confirmationText = ""
    @State private var confirmsRestore = false
    @State private var message: String?
    let service: any DatabaseBackupServicing
    let onRestoreScheduled: () async -> Void

    var body: some View {
        Form {
            if let state {
                Section("Retention") {
                    LabeledContent("Next automatic backup") {
                        Text(state.nextAutomaticBackupAt?.formatted(.dateTime) ?? "Not scheduled")
                    }
                    LabeledContent("Automatic retention", value: "\(state.automaticRetentionDays) days")
                    LabeledContent("Backup directory") {
                        Text(state.backupDirectory).font(.body.monospaced()).prismediaTextSelection()
                    }
                }
                Section("Backup Files") {
                    if state.backups.isEmpty { ContentUnavailableView("No Backups", systemImage: "archivebox") }
                    ForEach(state.backups) { AdministrativeDatabaseBackupRow(backup: $0) }
                }
                Section {
                    Picker("Completed backup", selection: $selectedBackupID) {
                        Text("Select a backup").tag(Optional<UUID>.none)
                        ForEach(completedBackups) { Text($0.fileName).tag(Optional($0.id)) }
                    }
                    TextField("Type \(state.restoreConfirmationText)", text: $confirmationText)
                        .prismediaPlainTextInput()
                        .disabled(selectedBackupID == nil)
                    Button("Restore and Restart", systemImage: "arrow.counterclockwise", role: .destructive) {
                        confirmsRestore = true
                    }
                    .disabled(!canRestore || isWorking)
                } header: {
                    Text("Destructive Restore")
                } footer: {
                    Text(
                        "Restore destroys the current database, applies the selected completed backup, restarts Prismedia, and requires a fresh sign-in. Type the confirmation exactly."
                    )
                }
            }
            if let message { Section { Text(message).foregroundStyle(PrismediaColor.destructive) } }
        }
        .overlay { if isLoading && state == nil { PrismediaLoadingView("Loading database backups…") } }
        .prismediaScreenBackground()
        .navigationTitle("Database Backups")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await load() } }.disabled(isLoading)
                Button("Backup Now", systemImage: "archivebox.badge.plus") { Task { await create() } }.disabled(
                    isWorking)
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .confirmationDialog("Restore this backup?", isPresented: $confirmsRestore, titleVisibility: .visible) {
            Button("Restore and Restart", role: .destructive) { Task { await restore() } }
        } message: {
            Text(
                "All current data will be replaced. Prismedia will restart and this app will discard its current session token."
            )
        }
        .accessibilityIdentifier("administration.settings.database-backups")
    }

    private var completedBackups: [AdministrativeDatabaseBackup] {
        state?.backups.filter { ["complete", "completed"].contains($0.status) } ?? []
    }
    private var canRestore: Bool {
        selectedBackupID != nil && confirmationText == state?.restoreConfirmationText
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            state = try await service.backups()
            selectedBackupID = selectedBackupID ?? completedBackups.first?.id
            message = nil
        } catch { message = error.localizedDescription }
    }

    private func create() async {
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await service.create()
            await load()
        } catch { message = error.localizedDescription }
    }

    private func restore() async {
        guard let selectedBackupID, let state else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await service.restore(id: selectedBackupID, confirmationText: state.restoreConfirmationText)
            await onRestoreScheduled()
        } catch { message = error.localizedDescription }
    }
}

#if DEBUG
    #Preview("Backups · Content") {
        NavigationStack {
            AdministrativeDatabaseBackupsView(service: Step3AdministrationPreviewService(), onRestoreScheduled: {})
        }
    }
#endif
