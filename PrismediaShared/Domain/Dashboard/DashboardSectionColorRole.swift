import Foundation

public enum DashboardSectionColorRole: String, Hashable, Sendable {
    case continueWatching
    case recent
    case video
    case movie
    case series
    case gallery
    case book
    case image
    case audio
    case collection
    case people
    case studios
    case tags

    public static func role(for kind: EntityKind) -> DashboardSectionColorRole {
        switch kind {
        case .video: .video
        case .movie: .movie
        case .videoSeries, .videoSeason: .series
        case .gallery: .gallery
        case .book, .bookVolume, .bookChapter, .bookPage, .bookAuthor: .book
        case .image: .image
        case .audio, .audioLibrary, .audioTrack, .musicArtist: .audio
        case .collection: .collection
        case .person: .people
        case .studio: .studios
        case .tag: .tags
        default:
            fallbackRoles[
                StableStringHash.paletteIndex(
                    for: kind.rawValue,
                    paletteCount: fallbackRoles.count
                )
            ]
        }
    }

    private static let fallbackRoles: [DashboardSectionColorRole] = [
        .video, .movie, .series, .gallery, .book, .image, .audio, .collection,
    ]
}
