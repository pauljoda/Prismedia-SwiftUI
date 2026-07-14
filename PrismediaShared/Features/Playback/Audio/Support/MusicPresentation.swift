import Foundation

public enum MusicPresentation {
    public static func clockTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds.rounded(.down))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    public static func artist(_ value: String?) -> String {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized?.isEmpty == false ? normalized! : "Unknown Artist"
    }

    public static func albumArtist(
        _ album: EntityThumbnail,
        artistNamesByID: [UUID: String] = [:]
    ) -> String {
        if let parentID = album.parentEntityID, let resolved = artistNamesByID[parentID] {
            return artist(resolved)
        }
        return artist(album.musicMetadataValue(matching: ["artist", "person"]))
    }

    public static func albumArtist(detail: EntityDetail, resolvedParentArtist: String? = nil) -> String {
        if let resolvedParentArtist { return artist(resolvedParentArtist) }
        let relatedArtist = detail.relationships
            .first { $0.kind == .musicArtist || $0.kind == .person }?
            .entities.first?.title
        return artist(relatedArtist)
    }

    public static func albumFacts(detail: EntityDetail, tracks: [MusicTrack]) -> MusicAlbumFacts {
        let released = detail.capabilities.compactMap { capability -> EntityItemsCapability<EntityDate>? in
            guard case .dates(let dates) = capability else { return nil }
            return dates
        }.flatMap(\.items).first { $0.code.localizedCaseInsensitiveContains("release") }?.value
        let year = released.map { String($0.prefix(4)) }
        let classification = detail.capabilities.compactMap { capability -> String? in
            guard case .classification(let value) = capability else { return nil }
            return value.value
        }.first
        let studio = detail.relationships.first { $0.kind == .studio }?.entities.first?.title
        let primary = [year, classification, studio].compactMap { $0 }.joined(separator: " • ")

        let discCount = Set(tracks.compactMap(\.discTitle)).count
        let duration = tracks.compactMap(\.duration).reduce(0, +)
        var secondary = ["\(tracks.count) \(tracks.count == 1 ? "song" : "songs")"]
        if discCount > 1 { secondary.append("\(discCount) discs") }
        if duration > 0 { secondary.append(clockTime(duration)) }
        return MusicAlbumFacts(primary: primary, secondary: secondary.joined(separator: " • "))
    }
}

extension MusicTrack {
    public init(
        thumbnail: EntityThumbnail,
        album: String? = nil,
        artist: String? = nil,
        artworkPath: String? = nil
    ) {
        let durationLabel = thumbnail.meta.first { $0.icon.localizedCaseInsensitiveContains("duration") }?.label
        let discTitle = thumbnail.musicMetadataValue(matching: ["disc", "section"])
        let trackNumber = thumbnail.musicMetadataValue(matching: ["track"])
            .flatMap(Self.trailingInteger)
        self.init(
            id: thumbnail.id,
            title: thumbnail.title,
            artist: artist ?? thumbnail.musicMetadataValue(matching: ["artist", "person"]),
            album: album ?? thumbnail.musicMetadataValue(matching: ["album", "library"]),
            artworkPath: thumbnail.bestCoverPath ?? artworkPath,
            duration: Self.seconds(from: durationLabel),
            discNumber: discTitle.flatMap(Self.trailingInteger),
            discTitle: discTitle,
            trackNumber: trackNumber,
            sortOrder: thumbnail.sortOrder ?? 0
        )
    }

    private static func trailingInteger(from value: String) -> Int? {
        value.split(whereSeparator: { !$0.isNumber }).last.flatMap { Int($0) }
    }

    private static func seconds(from clockTime: String?) -> Double? {
        guard let clockTime else { return nil }
        let parts = clockTime.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 || parts.count == 3 else { return nil }
        return parts.reduce(0) { ($0 * 60) + $1 }
    }
}

extension EntityThumbnail {
    func musicMetadataValue(matching keywords: [String]) -> String? {
        meta.first { item in
            keywords.contains { item.icon.localizedCaseInsensitiveContains($0) }
        }?.label
    }
}
