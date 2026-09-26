import Foundation

/// One addressable chapter within a physical audiobook track.
public struct BookAudioChapter: Codable, Equatable, Hashable, Sendable {
    public let audioTrackID: UUID
    public let audioMarkerID: UUID?
    public let title: String
    public let startSeconds: Double
    public let endSeconds: Double?

    /// Stable draft identity for a marker inside a physical file.
    public var identity: String {
        "\(audioTrackID.uuidString):\(audioMarkerID?.uuidString ?? "whole")"
    }

    public init(audioTrackID: UUID, audioMarkerID: UUID?, title: String, startSeconds: Double, endSeconds: Double?) {
        self.audioTrackID = audioTrackID
        self.audioMarkerID = audioMarkerID
        self.title = title
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case audioTrackID = "audioTrackId"
        case audioMarkerID = "audioMarkerId"
        case title, startSeconds, endSeconds
    }

    /// Server chapters take precedence; older responses still expose one candidate per file.
    /// Each ``identity`` appears once: a repeated track or marker keeps its first occurrence.
    public static func catalog(audioTracks: [MusicTrack], audioChapters: [BookAudioChapter]) -> [BookAudioChapter] {
        let tracks = audioTracks.sorted {
            ($0.sortOrder, $0.title, $0.id.uuidString)
                < ($1.sortOrder, $1.title, $1.id.uuidString)
        }
        var identities = Set<String>()
        let candidates = tracks.flatMap { track -> [BookAudioChapter] in
            let chapters = audioChapters.filter { $0.audioTrackID == track.id }
                .sorted { ($0.startSeconds, $0.title) < ($1.startSeconds, $1.title) }
            if !chapters.isEmpty { return chapters }
            return [BookAudioChapter(
                audioTrackID: track.id,
                audioMarkerID: nil,
                title: track.title,
                startSeconds: 0,
                endSeconds: track.duration
            )]
        }
        return candidates.filter { identities.insert($0.identity).inserted }
    }
}
