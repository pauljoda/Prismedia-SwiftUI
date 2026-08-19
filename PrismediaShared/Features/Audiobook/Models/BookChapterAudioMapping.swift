import Foundation

/// A persisted one-to-one association between a readable chapter and an audiobook track.
public struct BookChapterAudioMapping: Codable, Equatable, Hashable, Sendable {
    public let readableChapterKey: String
    public let audioTrackID: UUID

    public init(readableChapterKey: String, audioTrackID: UUID) {
        self.readableChapterKey = readableChapterKey
        self.audioTrackID = audioTrackID
    }

    private enum CodingKeys: String, CodingKey {
        case readableChapterKey
        case audioTrackID = "audioTrackId"
    }
}
