import Foundation

enum EntityMarkerSeekPolicy {
    static func canSeek(
        resolvedVideoID: UUID?,
        activeVideoID: UUID?
    ) -> Bool {
        guard let resolvedVideoID, let activeVideoID else { return false }
        return resolvedVideoID == activeVideoID
    }
}
