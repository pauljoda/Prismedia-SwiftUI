import Foundation

struct BookChapterMapping: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let order: Int
    let depth: Int
    let readTarget: BookChapterReadTarget?
    let readStartFraction: Double?
    let readEndFraction: Double?
    let readPageCount: Int?
    let audioTrack: MusicTrack?
    var isCurrentProgress: Bool

    init(
        id: String,
        title: String,
        order: Int,
        depth: Int,
        readTarget: BookChapterReadTarget?,
        readStartFraction: Double? = nil,
        readEndFraction: Double? = nil,
        readPageCount: Int? = nil,
        audioTrack: MusicTrack?,
        isCurrentProgress: Bool = false
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.depth = depth
        self.readTarget = readTarget
        self.readStartFraction = readStartFraction
        self.readEndFraction = readEndFraction
        self.readPageCount = readPageCount
        self.audioTrack = audioTrack
        self.isCurrentProgress = isCurrentProgress
    }
}
