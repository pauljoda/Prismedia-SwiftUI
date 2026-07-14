import Foundation

public struct EntityKind: RawRepresentable, Codable, Hashable, Identifiable, Sendable {
    public static let audio = EntityKind(rawValue: "audio")
    public static let video = EntityKind(rawValue: "video")
    public static let movie = EntityKind(rawValue: "movie")
    public static let videoSeries = EntityKind(rawValue: "video-series")
    public static let videoSeason = EntityKind(rawValue: "video-season")
    public static let gallery = EntityKind(rawValue: "gallery")
    public static let image = EntityKind(rawValue: "image")
    public static let book = EntityKind(rawValue: "book")
    public static let bookVolume = EntityKind(rawValue: "book-volume")
    public static let bookChapter = EntityKind(rawValue: "book-chapter")
    public static let bookPage = EntityKind(rawValue: "book-page")
    public static let person = EntityKind(rawValue: "person")
    public static let studio = EntityKind(rawValue: "studio")
    public static let tag = EntityKind(rawValue: "tag")
    public static let collection = EntityKind(rawValue: "collection")
    public static let audioLibrary = EntityKind(rawValue: "audio-library")
    public static let audioTrack = EntityKind(rawValue: "audio-track")
    public static let musicArtist = EntityKind(rawValue: "music-artist")
    public static let bookAuthor = EntityKind(rawValue: "book-author")

    public let rawValue: String
    public var id: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var displayLabel: String {
        switch self {
        case .audio: return "Audio"
        case .video: return "Video"
        case .movie: return "Movie"
        case .videoSeries: return "Series"
        case .videoSeason: return "Season"
        case .gallery: return "Gallery"
        case .image: return "Image"
        case .book: return "Book"
        case .bookVolume: return "Volume"
        case .bookChapter: return "Chapter"
        case .bookPage: return "Page"
        case .person: return "Person"
        case .studio: return "Studio"
        case .tag: return "Tag"
        case .collection: return "Collection"
        case .audioLibrary: return "Audio"
        case .audioTrack: return "Track"
        case .musicArtist: return "Artist"
        case .bookAuthor: return "Author"
        default: return rawValue.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    public var thumbnailAspectRatio: Double {
        switch self {
        case .video:
            return 16.0 / 9.0
        case .studio:
            return 21.0 / 9.0
        case .movie, .videoSeries, .videoSeason, .book, .bookAuthor, .bookVolume, .bookChapter, .bookPage:
            return 2.0 / 3.0
        case .person:
            return 4.0 / 5.0
        default:
            return 1
        }
    }

    public var prefersWideThumbnail: Bool {
        self == .video || self == .studio
    }
}
