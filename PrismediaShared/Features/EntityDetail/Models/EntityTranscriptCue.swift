import Foundation

struct EntityTranscriptCue: Identifiable, Hashable, Sendable {
    let id: Int
    let startTime: Double
    let endTime: Double
    let text: String
}
