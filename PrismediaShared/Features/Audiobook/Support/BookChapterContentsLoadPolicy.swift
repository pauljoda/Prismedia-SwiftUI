import Foundation

struct BookChapterContentsLoadPolicy: Sendable {
    static func canLoad(_ detail: EntityDetail) -> Bool {
        detail.kind == .book
            && detail.bookFormat == .epub
            && detail.hasSourceMedia
            && detail.capability(EntityFlagsCapability.self)?.isWanted != true
    }
}
