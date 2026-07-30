import Foundation

public enum DashboardSectionColorRole: Hashable, Sendable {
    case continueWatching
    case recent
    case entity(EntityKind)

    public static func role(for kind: EntityKind) -> DashboardSectionColorRole {
        .entity(kind)
    }
}
