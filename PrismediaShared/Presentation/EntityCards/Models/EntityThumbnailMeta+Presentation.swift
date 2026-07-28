import SwiftUI

extension EntityThumbnailMeta {
    var thumbnailSystemImage: String {
        switch normalizedThumbnailIcon {
        case "duration", "clock": "clock"
        case "calendar": "calendar"
        case "resolution": "rectangle"
        case "video": "film"
        case "season": "square.stack.3d.up"
        case "episode": "play.rectangle"
        case "image": "photo"
        case "gallery": "photo.stack"
        case "audio": "waveform"
        case "album": "square.stack"
        case "track": "music.note"
        case "disc": "opticaldisc"
        case "person": "person.2"
        case "artist": "music.mic"
        case "author": "person.crop.rectangle.stack"
        case "studio": "building.2"
        case "tag": "tag"
        case "progress": "gauge.with.dots.needle.bottom.50percent"
        case "codec", "format": "film"
        case "folder": "folder"
        case "book": "book.closed"
        case "volume": "books.vertical"
        case "chapter": "text.page"
        case "page": "doc"
        case "collection", "item", "count": "square.grid.2x2"
        default: "square.grid.2x2"
        }
    }

    var thumbnailAccessibilityLabel: String {
        guard label.allSatisfy(\.isNumber), let unit = thumbnailCountUnit else {
            return label
        }

        let renderedUnit = label == "1" ? unit.singular : unit.plural
        return "\(label) \(renderedUnit)"
    }

    var thumbnailTint: Color {
        switch normalizedThumbnailIcon {
        case "video", "season", "episode", "resolution", "codec", "format":
            PrismediaColor.entityAccent(for: .video)
        case "image", "gallery":
            PrismediaColor.entityAccent(for: .image)
        case "audio", "album", "track", "disc", "artist":
            PrismediaColor.entityAccent(for: .audio)
        case "book", "volume", "chapter", "page", "author":
            PrismediaColor.entityAccent(for: .book)
        case "collection", "item", "count", "folder":
            PrismediaColor.entityAccent(for: .collection)
        case "person":
            PrismediaColor.entityAccent(for: .person)
        case "studio":
            PrismediaColor.entityAccent(for: .studio)
        case "tag":
            PrismediaColor.entityAccent(for: .tag)
        default:
            PrismediaColor.textMuted
        }
    }

    private var normalizedThumbnailIcon: String {
        switch icon.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "video-season": "season"
        case "audio-library": "album"
        case "audio-track": "track"
        case "music-artist": "artist"
        case "book-author": "author"
        case "book-volume": "volume"
        case "book-chapter": "chapter"
        case "book-page": "page"
        default: icon.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    private var thumbnailCountUnit: (singular: String, plural: String)? {
        switch normalizedThumbnailIcon {
        case "season": ("season", "seasons")
        case "episode": ("episode", "episodes")
        case "video": ("video", "videos")
        case "image": ("image", "images")
        case "gallery": ("gallery", "galleries")
        case "album": ("album", "albums")
        case "track", "audio": ("track", "tracks")
        case "book": ("book", "books")
        case "volume": ("volume", "volumes")
        case "chapter": ("chapter", "chapters")
        case "page": ("page", "pages")
        case "collection", "item", "count": ("item", "items")
        case "person": ("person", "people")
        case "studio": ("studio", "studios")
        case "tag": ("tag", "tags")
        default: nil
        }
    }
}
