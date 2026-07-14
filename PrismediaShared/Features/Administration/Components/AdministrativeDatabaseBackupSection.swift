import SwiftUI

struct AdministrativeDatabaseBackupSection: View {
    let isWorking: Bool
    let onCreate: () async -> Void

    var body: some View {
        Section {
            Button {
                Task { await onCreate() }
            } label: {
                FullWidthButtonLabel {
                    Label("Back up database now", systemImage: "externaldrive.badge.plus")
                }
            }
            .disabled(isWorking)
        } footer: {
            Text("Creates a manual server-side backup using the configured backup storage.")
        }
    }
}

#if DEBUG
    #Preview("Database Backup") {
        Form {
            AdministrativeDatabaseBackupSection(isWorking: false, onCreate: {})
        }
    }
#endif
