import Foundation

public enum PrismediaEntityDeepLink {
    public static func link(from url: URL) -> EntityLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let scheme = components.scheme?.lowercased()
        guard scheme == "prismedia" || scheme == "https" || scheme == "http" else {
            return nil
        }

        if let queryLink = queryLink(from: components) {
            return queryLink
        }

        var segments = components.path.split(separator: "/").map(String.init)
        if scheme == "prismedia", let host = components.host, !host.isEmpty {
            segments.insert(host, at: 0)
        }
        if segments.first?.lowercased() == "entity" || segments.first?.lowercased() == "entities" {
            segments.removeFirst()
        }
        guard segments.count >= 2,
            let kind = kind(for: segments[0]),
            let entityID = UUID(uuidString: segments[1])
        else { return nil }

        return EntityLink(entityID: entityID, kind: kind, intent: intent(from: components))
    }

    private static func queryLink(from components: URLComponents) -> EntityLink? {
        let values = (components.queryItems ?? []).reduce(into: [String: String]()) {
            $0[$1.name.lowercased()] = $1.value ?? ""
        }
        guard let kindValue = values["kind"],
            let kind = kind(for: kindValue),
            let idValue = values["id"] ?? values["entityid"],
            let entityID = UUID(uuidString: idValue)
        else { return nil }
        return EntityLink(entityID: entityID, kind: kind, intent: intent(from: components))
    }

    private static func intent(from components: URLComponents) -> EntityNavigationIntent {
        let value = components.queryItems?
            .first { $0.name.lowercased() == "intent" }?
            .value?
            .lowercased()
        switch value {
        case "playback", "play": return .playback
        case "audio-collection", "audiocollection": return .audioCollection
        default: return .detail
        }
    }

    private static func kind(for routeValue: String) -> EntityKind? {
        switch routeValue.lowercased() {
        case "audio": return .audio
        case "video", "videos": return .video
        case "movie", "movies": return .movie
        case "video-series", "series": return .videoSeries
        case "video-season", "seasons": return .videoSeason
        case "gallery", "galleries": return .gallery
        case "image", "images": return .image
        case "book", "books": return .book
        case "book-volume", "volumes": return .bookVolume
        case "book-chapter", "chapters": return .bookChapter
        case "book-page", "pages": return .bookPage
        case "person", "people": return .person
        case "studio", "studios": return .studio
        case "tag", "tags": return .tag
        case "collection", "collections": return .collection
        case "audio-library", "album", "albums": return .audioLibrary
        case "audio-track", "track", "tracks": return .audioTrack
        case "music-artist", "artist", "artists": return .musicArtist
        case "book-author", "author", "authors": return .bookAuthor
        default: return nil
        }
    }
}
