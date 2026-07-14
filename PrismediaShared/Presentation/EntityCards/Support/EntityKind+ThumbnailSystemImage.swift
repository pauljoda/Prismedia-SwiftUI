extension EntityKind {
    var thumbnailFallbackSystemImage: String {
        switch self {
        case .audio: "waveform"
        case .video: "film"
        case .movie: "movieclapper"
        case .videoSeries, .videoSeason: "rectangle.stack"
        case .gallery: "photo.stack"
        case .image: "photo"
        case .book, .bookVolume: "book.closed"
        case .bookChapter: "text.book.closed"
        case .bookPage: "doc.richtext"
        case .person: "person.crop.rectangle"
        case .studio: "building.2"
        case .tag: "tag"
        case .collection: "square.stack.3d.up"
        case .audioLibrary: "square.stack"
        case .audioTrack: "music.note"
        case .musicArtist: "music.mic"
        case .bookAuthor: "signature"
        default: "photo"
        }
    }
}
