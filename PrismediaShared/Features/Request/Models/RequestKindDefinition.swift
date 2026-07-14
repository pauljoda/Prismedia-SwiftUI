import Foundation

public enum RequestKindDefinition: String, CaseIterable, Identifiable, Hashable, Sendable {
    case book
    case audiobook
    case author
    case movie
    case series
    case artist
    case album

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .book: "Book"
        case .audiobook: "Audiobook"
        case .author: "Author"
        case .movie: "Movie"
        case .series: "Series"
        case .artist: "Artist"
        case .album: "Album"
        }
    }

    public var pluralLabel: String {
        switch self {
        case .book: "Books"
        case .audiobook: "Audiobooks"
        case .author: "Authors"
        case .movie: "Movies"
        case .series: "Series"
        case .artist: "Artists"
        case .album: "Albums"
        }
    }

    public var childNoun: String? {
        switch self {
        case .book: "volume"
        case .author: "book"
        case .series: "season"
        case .artist: "album"
        default: nil
        }
    }

    public var entityKind: EntityKind {
        switch self {
        case .book, .audiobook: .book
        case .author: .bookAuthor
        case .movie: .movie
        case .series: .videoSeries
        case .artist: .musicArtist
        case .album: .audioLibrary
        }
    }

    public var pluginEntityKind: String {
        switch self {
        case .book, .audiobook: "book"
        case .author: "person"
        case .movie: "movie"
        case .series: "video-series"
        case .artist: "music-artist"
        case .album: "audio-library"
        }
    }

    public var profileKind: EntityKind {
        switch self {
        case .book, .audiobook, .author: .book
        case .movie: .movie
        case .series: .videoSeries
        case .artist, .album: .audioLibrary
        }
    }

    public var reviewSelection: RequestReviewSelectionMode {
        switch self {
        case .book: .directChildrenWhenPresent
        case .author, .series, .artist: .directChildren
        case .audiobook, .movie, .album: .root
        }
    }

    public func supports(root: AdministrativeLibraryRoot) -> Bool {
        switch self {
        case .book, .audiobook, .author: root.scanBooks
        case .movie, .series: root.scanVideos
        case .artist, .album: root.scanAudio
        }
    }
}
