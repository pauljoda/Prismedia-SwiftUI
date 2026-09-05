import SwiftUI

struct AdministrativeDiagnosticsStatusSections: View {
    let snapshot: AdministrativeDiagnosticsSnapshot

    var body: some View {
        Section("Health") {
            LabeledContent("API", value: snapshot.health.status.capitalized)
            LabeledContent("Worker", value: snapshot.worker.status.capitalized)
            LabeledContent("Database restore", value: restoreLabel)
            AdministrativeDetailsDisclosure("Runtime details") {
                LabeledContent("Runtime", value: snapshot.health.runtime ?? "Unknown")
                LabeledContent("Worker ID") {
                    Text(snapshot.worker.workerID ?? "Not reported")
                        .font(.caption.monospaced()).prismediaTextSelection()
                }
                LabeledContent("Last heartbeat") {
                    Text(snapshot.worker.lastSeenAt?.formatted(.dateTime) ?? "Never")
                }
                if let error = snapshot.restore.error {
                    Text(error).font(.subheadline).prismediaTextSelection()
                }
            }
        }
        Section("Storage") {
            LabeledContent("Backups", value: snapshot.backups.backups.count.formatted())
            LabeledContent("Retention", value: "\(snapshot.backups.automaticRetentionDays) days")
            AdministrativeDetailsDisclosure("Backup directory") {
                Text(snapshot.backups.backupDirectory).font(.body.monospaced()).prismediaTextSelection()
            }
        }
    }

    private var restoreLabel: String {
        if snapshot.restore.restoreFailed { return "Failed" }
        if snapshot.restore.restorePending { return "Pending" }
        return "Ready"
    }
}

#if DEBUG
    #Preview("Diagnostics Sections") {
        AdministrativeDiagnosticsView(isAdministrator: false, service: Step3AdministrationPreviewService())
    }
#endif
