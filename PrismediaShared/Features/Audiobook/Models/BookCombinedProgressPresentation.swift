import Foundation

struct BookCombinedProgressPresentation: Equatable, Sendable {
    let percent: Int
    let positionLabel: String?
    let chapterLabel: String?
    let status: MediaProgressStatus
    let activitySeconds: Double?
    let isLoading: Bool
    let isBusy: Bool

    init(
        progress: EntityProgressCapability?,
        reading: ReadingProgressPresentation?,
        chapterLabel: String? = nil,
        activitySeconds: Double?,
        isLoading: Bool,
        isBusy: Bool
    ) {
        let completed = progress?.completedAt != nil
        let rawPercent: Int
        if completed {
            rawPercent = 100
        } else if let progress {
            rawPercent = Int((progress.consumedPercent * 100).rounded())
        } else if let reading {
            rawPercent = reading.percent
        } else {
            rawPercent = 0
        }

        percent = min(max(0, rawPercent), 100)
        status = completed ? .completed : (percent > 0 ? .inProgress : .notStarted)
        if completed {
            positionLabel = nil
        } else if let readingLabel = reading?.positionLabel {
            positionLabel = readingLabel
        } else if let progress, progress.unit == .second, progress.total > 0 {
            positionLabel = "Current · \(MusicPresentation.clockTime(Double(progress.index))) of \(MusicPresentation.clockTime(Double(progress.total)))"
        } else if percent > 0 {
            positionLabel = "\(percent)% consumed"
        } else {
            positionLabel = nil
        }
        self.chapterLabel = chapterLabel
        self.activitySeconds = activitySeconds.flatMap {
            $0.isFinite && $0 > 0 ? $0 : nil
        }
        self.isLoading = isLoading
        self.isBusy = isBusy
    }
}
