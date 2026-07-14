public struct MusicTrackSection: Identifiable, Equatable, Sendable {
    public let title: String?
    public let tracks: [MusicTrack]
    public var id: String { title ?? "tracks" }

    public static func sections(for tracks: [MusicTrack]) -> [Self] {
        var titles: [String?] = []
        var grouped: [String: [MusicTrack]] = [:]
        for track in tracks {
            let title = track.discTitle
            let key = title ?? ""
            if !titles.contains(where: { $0 == title }) { titles.append(title) }
            grouped[key, default: []].append(track)
        }
        return titles.map { title in
            Self(title: title, tracks: grouped[title ?? "", default: []])
        }
    }
}
