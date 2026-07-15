import Foundation

struct BookCombinedProgressPresentation: Equatable, Sendable {
    let readingPercent: Int
    let readingPositionLabel: String?
    let listeningPercent: Int
    let listeningPositionLabel: String?
    let combinedContextLabel: String
    let readingStatus: MediaProgressStatus
    let listeningStatus: MediaProgressStatus
    let isBusy: Bool

    init(
        reading: ReadingProgressPresentation?,
        listening: AudiobookPlaybackPresentation?,
        combinedUsesReadingPosition: Bool,
        isBusy: Bool
    ) {
        readingPercent = reading?.percent ?? 0
        readingPositionLabel = reading?.positionLabel
        listeningPercent = listening?.progress.percent ?? 0
        listeningPositionLabel = listening?.progress.positionLabel
        combinedContextLabel =
            combinedUsesReadingPosition
            ? "Combined continues from your reading position"
            : "Combined continues from your listening position"
        readingStatus = reading?.status ?? .notStarted
        listeningStatus = listening?.progress.status ?? .notStarted
        self.isBusy = isBusy
    }
}
