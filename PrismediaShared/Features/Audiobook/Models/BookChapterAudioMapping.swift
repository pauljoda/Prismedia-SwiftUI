import Foundation

public struct BookChapterAudioMapping: Codable, Equatable, Hashable, Sendable {
    /// Server-declared provenance codes for one chapter association.
    public enum Origin {
        /// A pair the user chose explicitly; the only rows a save request may contain.
        public static let manual = "manual"
        /// A pair the server's scan-time title matcher derived; recomputed whenever inputs change.
        public static let auto = "auto"
    }

    public let readableChapterKey: String
    public let audioTrackID: UUID

    /// Mapping provenance (`manual` or `auto`). Absent on saves and on responses from servers
    /// that predate persisted automatic matching, both of which mean manual.
    public let origin: String?

    public init(readableChapterKey: String, audioTrackID: UUID, origin: String? = nil) {
        self.readableChapterKey = readableChapterKey
        self.audioTrackID = audioTrackID
        self.origin = origin
    }

    /// Whether the server derived this pair automatically. Automatic rows render like any other
    /// mapping but must never be echoed back in a save request — the server would then treat
    /// them as user choices and stop refreshing them when files or tracks change.
    public var isAutomatic: Bool { origin == Origin.auto }

    private enum CodingKeys: String, CodingKey {
        case readableChapterKey
        case audioTrackID = "audioTrackId"
        case origin
    }
}
