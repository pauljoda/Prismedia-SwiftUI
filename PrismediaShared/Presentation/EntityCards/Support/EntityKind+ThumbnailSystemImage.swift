extension EntityKind {
    var thumbnailFallbackSystemImage: String {
        guard let icon = definition?.presentation.icon else { return "photo" }
        return Self.thumbnailSystemImages[icon] ?? "photo"
    }

    private static let thumbnailSystemImages: [EntityKindIcon: String] = [
        .album: "square.stack",
        .artist: "music.mic",
        .audio: "waveform",
        .author: "signature",
        .book: "book.closed",
        .chapter: "text.book.closed",
        .collection: "square.stack.3d.up",
        .gallery: "photo.stack",
        .image: "photo",
        .movie: "movieclapper",
        .page: "doc.richtext",
        .person: "person.crop.rectangle",
        .season: "rectangle.stack",
        .series: "rectangle.stack",
        .studio: "building.2",
        .tag: "tag",
        .track: "music.note",
        .video: "film",
        .volume: "book.closed",
    ]
}
