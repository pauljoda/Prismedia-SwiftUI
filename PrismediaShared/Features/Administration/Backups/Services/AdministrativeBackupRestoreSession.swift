import Foundation
import Observation

/// Verifies one explicitly selected backup and requires confirmation again if its restore contract changes.
@MainActor @Observable
final class AdministrativeBackupRestoreSession {
    let backupID: UUID
    var confirmationText = ""
    private(set) var isRestoring = false
    private(set) var isScheduled = false
    private(set) var actionError: String?
    private var inventory = AdministrativeCollectionLoadState<AdministrativeDatabaseBackupList>()

    init(backupID: UUID) { self.backupID = backupID }

    var backup: AdministrativeDatabaseBackup? {
        inventory.items.first?.backups.first { $0.id == backupID }
    }
    var requiredConfirmation: String { inventory.items.first?.restoreConfirmationText ?? "" }
    var isLoading: Bool { inventory.isLoading }
    var loadError: String? { inventory.errorMessage }
    var isVerified: Bool { inventory.isReady && backup?.isRestorable == true }
    var canRestore: Bool {
        isVerified && !isRestoring && !isScheduled && !requiredConfirmation.isEmpty
            && confirmationText == requiredConfirmation
    }

    func dismissError() { actionError = nil }

    func load(service: any DatabaseBackupServicing) async {
        guard !isRestoring, !isScheduled else { return }
        await refresh(service: service)
    }

    /// Performs a fresh read immediately before sending the confirmed backup ID and typed phrase.
    func restore(service: any DatabaseBackupServicing) async -> Bool {
        guard canRestore else { return false }
        let expectedPhrase = requiredConfirmation
        isRestoring = true
        actionError = nil
        defer { isRestoring = false }
        await refresh(service: service)
        guard inventory.isReady else { return false }
        guard isVerified, expectedPhrase == requiredConfirmation,
            !requiredConfirmation.isEmpty, confirmationText == requiredConfirmation
        else {
            actionError = "The selected backup or confirmation has changed. Review it before trying again."
            return false
        }
        do {
            let response = try await service.restore(id: backupID, confirmationText: confirmationText)
            // A matching acknowledgement also accepts in-process restores without a host restart.
            guard response.backupID == backupID else {
                actionError = "The server did not confirm this restore. Check its status before trying again."
                return false
            }
            isScheduled = true
            return true
        } catch {
            actionError = "\(error.localizedDescription) Check the server's restore status before trying again."
            return false
        }
    }

    private func refresh(service: any DatabaseBackupServicing) async {
        let previousPhrase = requiredConfirmation
        let request = inventory.begin()
        do {
            let loaded = try await service.backups()
            inventory.succeed([loaded], request: request, isCancelled: Task.isCancelled)
            if inventory.isReady && (previousPhrase != requiredConfirmation || !isVerified) {
                confirmationText = ""
            }
        } catch {
            inventory.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }
}
