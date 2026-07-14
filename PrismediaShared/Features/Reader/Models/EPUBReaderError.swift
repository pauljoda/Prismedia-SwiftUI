import Foundation

public enum EPUBReaderError: Error, Equatable, LocalizedError, Sendable {
    case invalidArchive
    case archiveTooLarge
    case unsupportedCompression(UInt16)
    case unsafeArchivePath(String)
    case missingContainer
    case missingPackageDocument
    case malformedPackageDocument
    case emptySpine
    case unsupportedDRM

    public var errorDescription: String? {
        switch self {
        case .invalidArchive: "This EPUB archive is damaged or incomplete."
        case .archiveTooLarge: "This EPUB is too large to open safely on this device."
        case .unsupportedCompression: "This EPUB uses an unsupported archive compression method."
        case .unsafeArchivePath: "This EPUB contains an unsafe file path."
        case .missingContainer: "This EPUB is missing its container document."
        case .missingPackageDocument: "This EPUB is missing its package document."
        case .malformedPackageDocument: "This EPUB package document could not be read."
        case .emptySpine: "This EPUB does not contain readable chapters."
        case .unsupportedDRM: "DRM-protected EPUB books are not supported."
        }
    }
}
