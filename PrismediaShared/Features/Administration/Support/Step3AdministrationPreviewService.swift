import Foundation

#if DEBUG
    struct Step3AdministrationPreviewService: LibraryAdministrationServicing, UserAdministrationServicing,
        DiagnosticsServicing, DatabaseBackupServicing
    {
        private static let rootID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        private static let backupID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!

        func roots() async throws -> [AdministrativeLibraryRoot] { [Self.root] }
        func browse(path: String?) async throws -> AdministrativeLibraryBrowseResponse {
            AdministrativeLibraryBrowseResponse(
                path: path ?? "/media",
                parentPath: "/",
                directories: []
            )
        }
        func create(_ mutation: AdministrativeLibraryRootMutation) async throws -> AdministrativeLibraryRoot {
            Self.root
        }
        func update(id: UUID, mutation: AdministrativeLibraryRootMutation) async throws -> AdministrativeLibraryRoot {
            Self.root
        }
        func rescan(id: UUID) async throws -> Int { 1 }
        func replaceAccess(id: UUID, userIDs: [UUID]) async throws {}
        func delete(id: UUID) async throws {}

        func users() async throws -> [UserAccount] { [PrismediaPreviewData.user, Self.member] }
        func create(_ mutation: AdministrativeUserCreateMutation) async throws -> UserAccount { Self.member }
        func update(id: UUID, mutation: AdministrativeUserUpdateMutation) async throws -> UserAccount { Self.member }
        func resetPassword(id: UUID, newPassword: String) async throws {}
        func replaceLibraryAccess(id: UUID, rootIDs: [UUID]) async throws {}

        func snapshot() async throws -> AdministrativeDiagnosticsSnapshot {
            AdministrativeDiagnosticsSnapshot(
                health: HealthResponse(status: "ok", runtime: "dotnet"),
                worker: AdministrativeWorkerHealth(
                    status: "online",
                    workerID: "preview-worker",
                    lastSeenAt: Date(timeIntervalSince1970: 1_752_681_600),
                    staleAfterSeconds: 45
                ),
                backups: Self.backupList,
                restore: AdministrativeDatabaseRestoreStatus(restorePending: false, restoreFailed: false, error: nil)
            )
        }
        func rebuildPreviews() async throws -> AdministrativeBulkJobResponse { .init(enqueued: 24, skipped: 3) }
        func backfillFingerprints() async throws -> AdministrativeBulkJobResponse { .init(enqueued: 8, skipped: 120) }
        func backups() async throws -> AdministrativeDatabaseBackupList { Self.backupList }
        func create() async throws -> AdministrativeDatabaseBackup { Self.backup }
        func restore(id: UUID, confirmationText: String) async throws -> AdministrativeDatabaseRestoreScheduled {
            throw CancellationError()
        }
        func restoreStatus() async throws -> AdministrativeDatabaseRestoreStatus {
            AdministrativeDatabaseRestoreStatus(restorePending: false, restoreFailed: false, error: nil)
        }

        private static let root = AdministrativeLibraryRoot(
            id: rootID,
            path: "/media/movies",
            label: "Movies",
            enabled: true,
            scanVideos: true,
            lastScannedAt: Date(timeIntervalSince1970: 1_752_681_600)
        )
        private static let member = UserAccount(
            id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            username: "reader",
            displayName: "Library Reader",
            role: .member,
            allowNsfw: false,
            libraryRootIDs: [rootID]
        )
        private static let backup = AdministrativeDatabaseBackup(
            id: backupID,
            fileName: "manual-2026-07-16.sqlite",
            backupPath: "/data/backups/manual.sqlite",
            status: "completed",
            isManual: true,
            sizeBytes: 10_485_760,
            createdAt: Date(timeIntervalSince1970: 1_752_681_600),
            completedAt: Date(timeIntervalSince1970: 1_752_681_602),
            expiresAt: nil,
            error: nil
        )
        private static let backupList = AdministrativeDatabaseBackupList(
            backups: [backup],
            nextAutomaticBackupAt: Date(timeIntervalSince1970: 1_752_768_000),
            backupDirectory: "/data/backups",
            automaticRetentionDays: 7,
            restoreConfirmationText: "DESTROY AND RESTORE"
        )
    }
#endif
