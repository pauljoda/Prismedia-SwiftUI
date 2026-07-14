import Foundation

enum DashboardLoadResult: Sendable {
    case continueItems([EntityThumbnail])
    case recentItems([EntityThumbnail])
    case section(DashboardSectionDefinition, [EntityThumbnail])
}
