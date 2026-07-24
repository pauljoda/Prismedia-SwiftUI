import Foundation

public enum EntityGridCardStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case artworkFade
    case detailsBelow

    public var id: Self { self }

    public var label: String {
        switch self {
        case .artworkFade: "Artwork Fade"
        case .detailsBelow: "Text Below Artwork"
        }
    }

    public var systemImage: String {
        switch self {
        case .artworkFade: "photo.fill"
        case .detailsBelow: "text.below.photo"
        }
    }
}
