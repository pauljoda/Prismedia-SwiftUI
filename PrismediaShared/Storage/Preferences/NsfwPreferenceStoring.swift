import Foundation

/// Stores the explicit NSFW opt-in separately for each signed-in user. A
/// missing value is always safe-by-default.
@MainActor
public protocol NsfwPreferenceStoring {
    func load(for userID: UUID) -> Bool
    func save(_ allowsNsfwContent: Bool, for userID: UUID)
}
