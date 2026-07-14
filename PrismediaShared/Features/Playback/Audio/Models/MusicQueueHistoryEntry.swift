import Foundation

public struct MusicQueueHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public let sequence: UInt64
    public let track: MusicTrack

    public init(sequence: UInt64, track: MusicTrack) {
        self.sequence = sequence
        self.track = track
    }

    public var id: String {
        "\(sequence):\(track.id.uuidString)"
    }
}
