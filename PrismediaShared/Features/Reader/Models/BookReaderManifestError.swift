import Foundation

public enum BookReaderManifestError: Error, LocalizedError {
    case unsupportedEntity(EntityKind)
    case missingParent(EntityKind)
    case missingBook
    case noReadablePages

    public var errorDescription: String? {
        switch self {
        case .unsupportedEntity: "This item cannot be opened in the comic reader."
        case .missingParent: "The reader could not resolve this item’s book."
        case .missingBook: "The reader could not find the owning book."
        case .noReadablePages: "This book has no readable image pages."
        }
    }
}
