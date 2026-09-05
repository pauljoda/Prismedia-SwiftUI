import Foundation

/// Editable account values, separate from the last account confirmed by the server.
struct AdministrativeUserDraft {
    var username: String
    var displayName: String
    var password = ""
    var role: UserRole
    var allowNsfw: Bool
    var canCreateLibraries: Bool
    var canRequestContent: Bool
    var enabled: Bool
    var rootIDs: Set<UUID>

    init(user: UserAccount?) {
        username = user?.username ?? ""
        displayName = user?.displayName ?? ""
        role = user?.role ?? .member
        allowNsfw = user?.allowNsfw ?? false
        canCreateLibraries = user?.canCreateLibraries ?? false
        canRequestContent = user?.canRequestContent ?? false
        enabled = user?.enabled ?? true
        rootIDs = Set(user?.libraryRootIDs ?? [])
    }

    func isValid(requiresPassword: Bool) -> Bool {
        (1...64).contains(trimmedUsername.count) && (!requiresPassword || password.count >= 8)
    }

    mutating func setAllowNsfw(_ allowed: Bool, roots: [AdministrativeLibraryRoot]) {
        allowNsfw = allowed
        if !allowed { rootIDs.subtract(roots.filter(\.isNsfw).map(\.id)) }
    }

    var createMutation: AdministrativeUserCreateMutation {
        AdministrativeUserCreateMutation(
            username: trimmedUsername, password: password,
            displayName: trimmedDisplayName.isEmpty ? nil : trimmedDisplayName,
            role: role, allowNsfw: allowNsfw, canCreateLibraries: canCreateLibraries,
            canRequestContent: canRequestContent, enabled: enabled
        )
    }

    func updateMutation(isSelf: Bool) -> AdministrativeUserUpdateMutation {
        AdministrativeUserUpdateMutation(
            username: trimmedUsername, displayName: trimmedDisplayName,
            role: isSelf ? nil : role, allowNsfw: allowNsfw,
            canCreateLibraries: canCreateLibraries, canRequestContent: canRequestContent,
            enabled: isSelf ? nil : enabled
        )
    }

    private var trimmedUsername: String { username.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedDisplayName: String { displayName.trimmingCharacters(in: .whitespacesAndNewlines) }
}
