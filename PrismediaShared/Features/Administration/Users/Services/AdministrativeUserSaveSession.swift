import Foundation
import Observation

/// Retains confirmed account writes so a failed library-access request can be retried safely.
@Observable @MainActor
final class AdministrativeUserSaveSession {
    private(set) var account: UserAccount?
    private(set) var hasSavedAccount = false
    private(set) var libraryAccessNeedsRetry = false
    private(set) var isSaving = false
    private(set) var error: String?

    init(user: UserAccount?) { account = user }

    func dismissError() { error = nil }

    /// Saves one immutable draft, then its library grants. A confirmed creation is never repeated.
    func save(
        _ draft: AdministrativeUserDraft,
        currentUserID: UUID,
        service: any UserAdministrationServicing
    ) async -> UserAccount? {
        guard !isSaving, draft.isValid(requiresPassword: account == nil) else { return nil }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let saved: UserAccount
            if let account {
                saved = try await service.update(
                    id: account.id,
                    mutation: draft.updateMutation(isSelf: account.id == currentUserID)
                )
            } else {
                saved = try await service.create(draft.createMutation)
            }
            account = saved
            hasSavedAccount = true
            if !saved.isAdmin {
                libraryAccessNeedsRetry = true
                try await service.replaceLibraryAccess(id: saved.id, rootIDs: Array(draft.rootIDs))
            }
            libraryAccessNeedsRetry = false
            return saved
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
