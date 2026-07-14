import Foundation

public enum RequestReviewSelectionMode: String, Hashable, Sendable {
    case root
    case directChildren = "direct-children"
    case directChildrenWhenPresent = "direct-children-when-present"
}
