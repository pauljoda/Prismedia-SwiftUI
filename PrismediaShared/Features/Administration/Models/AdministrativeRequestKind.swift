import Foundation

public enum AdministrativeRequestKind: String, CaseIterable, Identifiable, Sendable {
    case movie
    case series
    case book
    case audiobook
    case author
    case album
    case artist

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .movie: "Movie"
        case .series: "Series"
        case .book: "Book"
        case .audiobook: "Audiobook"
        case .author: "Author"
        case .album: "Album"
        case .artist: "Artist"
        }
    }

    public var entityKind: String {
        switch self {
        case .movie: "movie"
        case .series: "video-series"
        case .book, .audiobook: "book"
        case .author: "book-author"
        case .album: "audio-library"
        case .artist: "music-artist"
        }
    }
}
