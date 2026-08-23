import Foundation

struct BookChapterContentsLoadPolicy: Sendable {
    static func canLoad(_ detail: EntityDetail) -> Bool {
        guard detail.kind == .book,
            detail.capability(EntityFlagsCapability.self)?.isWanted != true
        else { return false }
        return true
    }
}
