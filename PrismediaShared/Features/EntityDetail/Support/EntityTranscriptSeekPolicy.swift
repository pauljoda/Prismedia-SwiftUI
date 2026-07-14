import Foundation

enum EntityTranscriptSeekPolicy {
    static func canSeek(
        ownerLink: EntityLink?,
        resolvedVideoID: UUID?,
        activeOwnerLink: EntityLink?,
        activeVideoID: UUID?
    ) -> Bool {
        guard let ownerLink, let resolvedVideoID else { return false }
        return ownerLink == activeOwnerLink && resolvedVideoID == activeVideoID
    }
}
