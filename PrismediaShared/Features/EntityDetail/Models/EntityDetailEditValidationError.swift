import Foundation

enum EntityDetailEditValidationError: LocalizedError, Hashable, Sendable {
    case emptyTitle
    case invalidRating
    case invalidURL(String)
    case invalidNumber(section: String, key: String)

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            "Title cannot be empty."
        case .invalidRating:
            "Rating must be between 0 and 5."
        case .invalidURL(let value):
            "\(value) is not an absolute HTTP or HTTPS URL."
        case .invalidNumber(let section, let key):
            "\(section) value for \(key.isEmpty ? "an unnamed field" : key) must be a whole number."
        }
    }
}
