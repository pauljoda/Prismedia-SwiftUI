import SwiftUI

struct AdministrativeBackupDetailView: View {
    let backup: AdministrativeDatabaseBackup
    let service: any DatabaseBackupServicing
    let onRestoreScheduled: () async -> Void

    var body: some View {
        Form {
            Section {
                AdministrativeDatabaseBackupRow(backup: backup)
            }
            Section("File") {
                Text(backup.fileName).font(.body.monospaced()).prismediaTextSelection()
                AdministrativeDetailsDisclosure("Server path") {
                    Text(backup.backupPath).font(.body.monospaced()).prismediaTextSelection()
                }
                if let completedAt = backup.completedAt {
                    LabeledContent("Finished") { Text(completedAt, format: .dateTime) }
                }
                LabeledContent("Retention") {
                    if backup.isManual {
                        Text("Permanent")
                    } else if let expiresAt = backup.expiresAt {
                        Text(expiresAt, format: .dateTime)
                    } else {
                        Text("Automatic")
                    }
                }
            }
            if let error = backup.error {
                Section("Backup Failed") {
                    Text(error).font(.subheadline).prismediaTextSelection()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if backup.isRestorable {
                Section {
                    NavigationLink {
                        AdministrativeBackupRestoreConfirmationView(
                            backup: backup, service: service, onRestoreScheduled: onRestoreScheduled)
                    } label: {
                        Label("Restore This Backup", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(PrismediaColor.destructive)
                    }
                } footer: {
                    Text("Replaces the current database. You will review and confirm before anything changes.")
                }
            }
        }
        .prismediaSettingsForm()
        .prismediaScreenBackground()
        .navigationTitle("Backup Details")
    }
}

#if DEBUG
    #Preview("Backup Details") {
        NavigationStack {
            AdministrativeBackupDetailView(
                backup: Step3AdministrationPreviewService.backup,
                service: Step3AdministrationPreviewService(), onRestoreScheduled: {})
        }
    }
#endif
