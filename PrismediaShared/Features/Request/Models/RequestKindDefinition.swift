// AUTO-GENERATED from Prismedia's backend request-kind manifest.
// Do not edit by hand. Run `python3 Scripts/generate-request-kind-definitions.py`.

import Foundation

public enum RequestKindDefinition: String, CaseIterable, Identifiable, Hashable, Sendable {
    case book
    case audiobook
    case author
    case movie
    case series
    case season
    case episode
    case comicSeries = "comic-series"
    case comicVolume = "comic-volume"
    case comicInstallment = "comic-installment"
    case artist
    case album
    case track

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .book: "Book"
        case .audiobook: "Audiobook"
        case .author: "Author"
        case .movie: "Movie"
        case .series: "Series"
        case .season: "Season"
        case .episode: "Episode"
        case .comicSeries: "Comic Series"
        case .comicVolume: "Comic Volume"
        case .comicInstallment: "Comic Installment"
        case .artist: "Artist"
        case .album: "Album"
        case .track: "Track"
        }
    }

    public var pluralLabel: String {
        switch self {
        case .book: "Books"
        case .audiobook: "Audiobooks"
        case .author: "Authors"
        case .movie: "Movies"
        case .series: "Series"
        case .season: "Seasons"
        case .episode: "Episodes"
        case .comicSeries: "Comic Series"
        case .comicVolume: "Comic Volumes"
        case .comicInstallment: "Comic Installments"
        case .artist: "Artists"
        case .album: "Albums"
        case .track: "Tracks"
        }
    }

    public var childNoun: String? {
        switch self {
        case .book: return "volume"
        case .audiobook: return nil
        case .author: return "book"
        case .movie: return nil
        case .series: return "season"
        case .season: return "episode"
        case .episode: return nil
        case .comicSeries: return "release"
        case .comicVolume: return "installment"
        case .comicInstallment: return nil
        case .artist: return "album"
        case .album: return "track"
        case .track: return nil
        }
    }

    public var entityKind: EntityKind {
        switch self {
        case .book: return .book
        case .audiobook: return .book
        case .author: return .bookAuthor
        case .movie: return .movie
        case .series: return .videoSeries
        case .season: return .videoSeason
        case .episode: return .videoEpisode
        case .comicSeries: return .comicSeries
        case .comicVolume: return .comicVolume
        case .comicInstallment: return .comicInstallment
        case .artist: return .musicArtist
        case .album: return .audioLibrary
        case .track: return .audioTrack
        }
    }

    public var pluginEntityKind: String {
        switch self {
        case .book: "book"
        case .audiobook: "book"
        case .author: "person"
        case .movie: "movie"
        case .series: "video-series"
        case .season: "video-season"
        case .episode: "video-episode"
        case .comicSeries: "comic-series"
        case .comicVolume: "comic-volume"
        case .comicInstallment: "comic-installment"
        case .artist: "music-artist"
        case .album: "audio-library"
        case .track: "audio-track"
        }
    }

    public var acquisitionKind: EntityKind {
        switch self {
        case .book: return .book
        case .audiobook: return .book
        case .author: return .book
        case .movie: return .movie
        case .series: return .videoSeason
        case .season: return .videoSeason
        case .episode: return .videoEpisode
        case .comicSeries: return .comicVolume
        case .comicVolume: return .comicVolume
        case .comicInstallment: return .comicInstallment
        case .artist: return .audioLibrary
        case .album: return .audioLibrary
        case .track: return .audioTrack
        }
    }

    public var profileKind: EntityKind {
        switch self {
        case .book: return .book
        case .audiobook: return .book
        case .author: return .book
        case .movie: return .movie
        case .series: return .videoSeries
        case .season: return .videoSeries
        case .episode: return .videoSeries
        case .comicSeries: return .comicSeries
        case .comicVolume: return .comicSeries
        case .comicInstallment: return .comicSeries
        case .artist: return .audioLibrary
        case .album: return .audioLibrary
        case .track: return .audioLibrary
        }
    }

    public var reviewSelection: RequestReviewSelectionMode {
        switch self {
        case .book: return .directChildrenWhenPresent
        case .audiobook: return .root
        case .author: return .directChildren
        case .movie: return .root
        case .series: return .directChildren
        case .season: return .root
        case .episode: return .root
        case .comicSeries: return .directChildren
        case .comicVolume: return .root
        case .comicInstallment: return .root
        case .artist: return .directChildren
        case .album: return .root
        case .track: return .root
        }
    }

    public var isCommittable: Bool {
        switch self {
        case .book: return true
        case .audiobook: return true
        case .author: return true
        case .movie: return true
        case .series: return true
        case .season: return true
        case .episode: return true
        case .comicSeries: return true
        case .comicVolume: return true
        case .comicInstallment: return true
        case .artist: return true
        case .album: return true
        case .track: return true
        }
    }

    public var isDiscoverable: Bool {
        switch self {
        case .book: return true
        case .audiobook: return true
        case .author: return true
        case .movie: return true
        case .series: return true
        case .season: return false
        case .episode: return false
        case .comicSeries: return true
        case .comicVolume: return false
        case .comicInstallment: return false
        case .artist: return true
        case .album: return true
        case .track: return false
        }
    }

    public static var discoverable: [Self] { allCases.filter(\.isDiscoverable) }

    public func supports(root: RequestLibraryRoot) -> Bool {
        switch self {
        case .book: return root.scanBooks
        case .audiobook: return root.scanBooks
        case .author: return root.scanBooks
        case .movie: return root.scanVideos
        case .series: return root.scanVideos
        case .season: return root.scanVideos
        case .episode: return root.scanVideos
        case .comicSeries: return root.scanBooks
        case .comicVolume: return root.scanBooks
        case .comicInstallment: return root.scanBooks
        case .artist: return root.scanAudio
        case .album: return root.scanAudio
        case .track: return root.scanAudio
        }
    }
}
