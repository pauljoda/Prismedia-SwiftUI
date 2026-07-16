import Foundation

public enum SearchHubKindCatalog {
    public static let kinds: [EntityKind] = [
        .movie,
        .videoSeries,
        .video,
        .person,
        .studio,
        .tag,
        .gallery,
        .book,
        .image,
        .collection,
        .audioLibrary,
        .audioTrack,
    ]

    public static var allKinds: Set<EntityKind> {
        Set(kinds)
    }

    public static func label(for kind: EntityKind) -> String {
        switch kind {
        case .movie: "Movies"
        case .videoSeries: "Series"
        case .video: "Videos"
        case .person: "People"
        case .studio: "Studios"
        case .tag: "Tags"
        case .gallery: "Galleries"
        case .book: "Books"
        case .image: "Images"
        case .collection: "Collections"
        case .audioLibrary: "Audio Libraries"
        case .audioTrack: "Audio Tracks"
        default: kind.displayLabel
        }
    }

    public static func systemImage(for kind: EntityKind) -> String {
        switch kind {
        case .movie: "movieclapper"
        case .videoSeries: "rectangle.stack"
        case .video: "play.rectangle"
        case .person: "person.2"
        case .studio: "building.2"
        case .tag: "tag"
        case .gallery: "photo.stack"
        case .book: "book.closed"
        case .image: "photo"
        case .collection: "square.stack.3d.up"
        case .audioLibrary: "music.note.list"
        case .audioTrack: "music.note"
        default: "square.grid.2x2"
        }
    }
}
