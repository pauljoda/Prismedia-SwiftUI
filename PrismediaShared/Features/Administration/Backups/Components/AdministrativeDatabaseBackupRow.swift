import SwiftUI

struct AdministrativeDatabaseBackupRow: View {
    let backup: AdministrativeDatabaseBackup

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Label(backup.isManual ? "Manual backup" : "Automatic backup",
                  systemImage: backup.isManual ? "archivebox" : "clock.arrow.circlepath")
                .font(.headline)
            Text(backup.createdAt, format: .dateTime.year().month().day().hour().minute())
                .font(.subheadline)
            HStack(spacing: PrismediaSpacing.small) {
                Label(status, systemImage: statusIcon)
                if let size = backup.sizeBytes {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                }
            }
            .font(.caption)
            .foregroundStyle(backup.status == PrismediaContractCodes.DatabaseBackupStatus.failed
                ? PrismediaColor.destructive : PrismediaColor.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        switch backup.status {
        case PrismediaContractCodes.DatabaseBackupStatus.completed: "Completed"
        case PrismediaContractCodes.DatabaseBackupStatus.running: "In progress"
        case PrismediaContractCodes.DatabaseBackupStatus.failed: "Failed"
        default: "Unknown status"
        }
    }

    private var statusIcon: String {
        switch backup.status {
        case PrismediaContractCodes.DatabaseBackupStatus.completed: "checkmark.circle"
        case PrismediaContractCodes.DatabaseBackupStatus.running: "clock"
        case PrismediaContractCodes.DatabaseBackupStatus.failed: "exclamationmark.circle"
        default: "questionmark.circle"
        }
    }
}

#if DEBUG
    #Preview {
        AdministrativeDatabaseBackupRow(
            backup: AdministrativeDatabaseBackup(
                id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
                fileName: "manual-2026-07-16.sqlite",
                backupPath: "/data/backups/manual.sqlite",
                status: PrismediaContractCodes.DatabaseBackupStatus.completed,
                isManual: true,
                sizeBytes: 10_485_760,
                createdAt: Date(timeIntervalSince1970: 1_752_681_600),
                completedAt: Date(timeIntervalSince1970: 1_752_681_602),
                expiresAt: nil,
                error: nil
            )
        )
        .padding()
    }
#endif
