import Foundation

struct BookChapterContentsLoadPolicy: Sendable {
    static func canLoad(_ detail: EntityDetail) -> Bool {
        guard detail.kind == .book,
            detail.capability(EntityFlagsCapability.self)?.isWanted != true
        else { return false }

        switch detail.bookFormat {
        case .epub:
            return detail.hasSourceMedia
        case .imageArchive:
            return true
        default:
            return false
        }
    }
}
