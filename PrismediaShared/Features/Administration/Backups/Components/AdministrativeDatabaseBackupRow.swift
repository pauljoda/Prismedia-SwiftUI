import SwiftUI

struct AdministrativeDatabaseBackupRow: View {
    let backup: AdministrativeDatabaseBackup

    var body: some View {
        HStack(spacing: PrismediaSpacing.medium) {
            Image(systemName: backup.isManual ? "archivebox.fill" : "clock.arrow.circlepath")
                .foregroundStyle(backup.status == "failed" ? PrismediaColor.destructive : PrismediaColor.accent)
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(backup.fileName).lineLimit(1)
                Text("\((backup.completedAt ?? backup.createdAt).formatted(.dateTime)) · \(size)")
                    .font(.caption).foregroundStyle(.secondary)
                if let error = backup.error { Text(error).font(.caption2).foregroundStyle(PrismediaColor.destructive) }
            }
            Spacer()
            Text(status).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var size: String { ByteCountFormatter.string(fromByteCount: backup.sizeBytes ?? 0, countStyle: .file) }
    private var status: String {
        if backup.status == "failed" { return "Failed" }
        if backup.status == "running" { return "Running" }
        return backup.isManual ? "Permanent" : "Auto"
    }
}

#if DEBUG
    #Preview {
        AdministrativeDatabaseBackupRow(
            backup: AdministrativeDatabaseBackup(
                id: UUID(),
                fileName: "manual-2026-07-16.sqlite",
                backupPath: "/data/backups/manual.sqlite",
                status: "completed",
                isManual: true,
                sizeBytes: 10_485_760,
                createdAt: .now,
                completedAt: .now,
                expiresAt: nil,
                error: nil
            )
        )
        .padding()
    }
#endif
