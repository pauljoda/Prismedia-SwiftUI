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
    let audioMarkerID: UUID?
    let audioStartSeconds: Double?
    let audioEndSeconds: Double?
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
        audioMarkerID: UUID? = nil,
        audioStartSeconds: Double? = nil,
        audioEndSeconds: Double? = nil,
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
        self.audioMarkerID = audioMarkerID
        self.audioStartSeconds = audioStartSeconds
        self.audioEndSeconds = audioEndSeconds
        self.isCurrentProgress = isCurrentProgress
    }
}

extension BookChapterMapping {
    /// A chapter row presenting one server alignment row. The row's audio side resolves to a
    /// playable part of `tracksByID`; an audio window whose part is not playable shows no Listen
    /// action.
    init(row: BookAlignmentRow, tracksByID: [UUID: MusicTrack], isCurrentProgress: Bool) {
        self.init(
            id: row.id,
            title: row.readable?.title ?? row.audio?.title ?? "",
            order: row.order,
            depth: row.readable?.depth ?? 0,
            readTarget: row.readable?.readTarget,
            readStartFraction: row.readable?.startFraction,
            readEndFraction: row.readable?.endFraction,
            readPageCount: row.readable?.pageCount,
            audioTrack: row.audio.flatMap { tracksByID[$0.trackEntityID] },
            audioMarkerID: row.audio?.markerID,
            audioStartSeconds: row.audio?.startSeconds,
            audioEndSeconds: row.audio?.endSeconds,
            isCurrentProgress: isCurrentProgress
        )
    }
}
