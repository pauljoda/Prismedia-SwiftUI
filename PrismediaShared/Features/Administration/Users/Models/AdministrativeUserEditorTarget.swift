import Foundation

public struct AdministrativeUserEditorTarget: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let user: UserAccount?

    public init(user: UserAccount? = nil) {
        self.user = user
        id = user?.id ?? UUID()
    }
}
