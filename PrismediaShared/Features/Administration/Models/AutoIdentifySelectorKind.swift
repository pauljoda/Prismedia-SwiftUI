import Foundation

enum AutoIdentifySelectorKind: String, CaseIterable, Sendable {
    case video = "video"
    case gallery = "gallery"
    case image = "image"
    case audio = "audio"
    case book = "book"

    var displayLabel: String {
        switch self {
        case .video: "Videos"
        case .gallery: "Galleries"
        case .image: "Images"
        case .audio: "Audio"
        case .book: "Books"
        }
    }
}
