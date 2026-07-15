import Foundation

struct BookChapterMapping: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let order: Int
    let depth: Int
    let readTarget: BookChapterReadTarget?
    let audioTrack: MusicTrack?
    let isCurrentReading: Bool
    let isCurrentAudio: Bool
}
