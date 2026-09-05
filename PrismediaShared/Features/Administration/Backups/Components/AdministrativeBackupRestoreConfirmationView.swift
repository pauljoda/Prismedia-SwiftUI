import SwiftUI

struct AdministrativeBackupRestoreConfirmationView: View {
    @State private var session: AdministrativeBackupRestoreSession
    @State private var confirmsRestore = false
    let backup: AdministrativeDatabaseBackup
    let service: any DatabaseBackupServicing
    let onRestoreScheduled: () async -> Void

    init(backup: AdministrativeDatabaseBackup, service: any DatabaseBackupServicing,
         onRestoreScheduled: @escaping () async -> Void) {
        self.backup = backup
        self.service = service
        self.onRestoreScheduled = onRestoreScheduled
        _session = State(initialValue: AdministrativeBackupRestoreSession(backupID: backup.id))
    }

    var body: some View {
        Form {
            Section("Selected Backup") {
                AdministrativeDatabaseBackupRow(backup: session.backup ?? backup)
                Text(backup.fileName).font(.caption.monospaced()).prismediaTextSelection()
            }
            Section {
                Label("Replaces the current database", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                Text("Current data will be replaced with this backup. Prismedia may restart, and you will need to sign in again.")
            }
            if let error = session.loadError {
                PrismediaRetryView(
                    title: "Couldn't Verify Backup", message: error,
                    retry: { Task { await session.load(service: service) } })
            } else if session.isLoading {
                ProgressView("Verifying backup…")
            } else if !session.isVerified {
                ContentUnavailableView(
                    "Backup Unavailable for Restore", systemImage: "archivebox",
                    description: Text("Return to backups and choose a completed backup."))
            } else {
                Section {
                    Text(session.requiredConfirmation).font(.body.monospaced())
                    PrismediaFormField("Confirmation") {
                        TextField("Confirmation", text: $session.confirmationText, prompt: Text("Enter the phrase above"))
                            .prismediaPlainTextInput()
                    }
                } header: {
                    Text("Type to Confirm")
                }
                Section {
                    Button(role: .destructive) { confirmsRestore = true } label: {
                        FullWidthButtonLabel {
                            Label("Restore Database", systemImage: "arrow.counterclockwise")
                        }
                    }
                    .disabled(!session.canRestore)
                }
            }
            if session.isRestoring || session.isScheduled {
                ProgressView(session.isScheduled ? "Restoring database…" : "Scheduling restore…")
            }
        }
        .disabled(session.isRestoring || session.isScheduled)
        .prismediaSettingsForm()
        .prismediaScreenBackground()
        .navigationTitle("Restore Backup")
        .navigationBarBackButtonHidden(session.isRestoring || session.isScheduled)
        .interactiveDismissDisabled(session.isRestoring || session.isScheduled)
        .task { await session.load(service: service) }
        .confirmationDialog("Replace the current database?", isPresented: $confirmsRestore, titleVisibility: .visible) {
            Button("Restore Database", role: .destructive) {
                Task {
                    if await session.restore(service: service) { await onRestoreScheduled() }
                }
            }
        } message: {
            Text("Restore \(backup.fileName)? All current data will be replaced. Prismedia may restart and you will need to sign in again.")
        }
        .alert(
            "Restore Not Confirmed",
            isPresented: Binding(get: { session.actionError != nil }, set: { if !$0 { session.dismissError() } })
        ) {
            Button("OK", role: .cancel) { session.dismissError() }
        } message: {
            Text(session.actionError ?? "")
        }
    }
}

#if DEBUG
    #Preview("Restore Confirmation · Accessibility") {
        NavigationStack {
            AdministrativeBackupRestoreConfirmationView(
                backup: Step3AdministrationPreviewService.backup,
                service: Step3AdministrationPreviewService(), onRestoreScheduled: {})
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
