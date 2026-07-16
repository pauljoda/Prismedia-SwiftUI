import Foundation

public enum EntityGridSelectionAction: Hashable, Sendable {
    case addToCollection
    case markNsfw(Bool)
    case removeWanted
    case custom(String)
}
