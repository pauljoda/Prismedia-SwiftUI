import Foundation

/// What the Read & Listen card shows. A Linked Book (and every Book on servers without the link
/// decision) keeps one overall progress and the combined action; a Separate Book shows reading and
/// listening as two meters with the reason, and offers only each format's own resume.
struct BookCombinedProgressPresentation: Equatable, Sendable {
    // MARK: - Variables

    let actions: BookCombinedProgressActions
    let percent: Int
    let positionLabel: String?
    let chapterLabel: String?
    let status: MediaProgressStatus
    let activitySeconds: Double?
    let isLoading: Bool
    let isBusy: Bool
    /// Why reading and listening are tracked separately; nil for a Linked Book.
    let separateExplanation: String?
    /// Reading and listening meters of an unfinished Separate Book; nil draws the overall meter.
    let separateMeters: EntitySeparateProgress?

    /// Whether switching and reading-while-listening follow the Book's paired chapters.
    var isLinked: Bool {
        separateExplanation == nil
    }

    // MARK: - Initializers

    init(
        progress: EntityProgressCapability?,
        reading: ReadingProgressPresentation?,
        chapterLabel: String? = nil,
        activitySeconds: Double?,
        isLoading: Bool,
        isBusy: Bool,
        actions: BookCombinedProgressActions = .continueEach,
        separate: EntitySeparateProgress? = nil
    ) {
        let completed = progress?.completedAt != nil
        let meters = completed ? nil : separate
        let rawPercent: Int
        if completed {
            rawPercent = 100
        } else if let meters {
            rawPercent = meters.readingPercent
        } else if let progress {
            rawPercent = Int((progress.consumedPercent * 100).rounded())
        } else if let reading {
            rawPercent = reading.percent
        } else {
            rawPercent = 0
        }

        percent = min(max(0, rawPercent), 100)
        let started = percent > 0 || (meters?.listeningPercent ?? 0) > 0
        status = completed ? .completed : (started ? .inProgress : .notStarted)
        if completed {
            positionLabel = nil
        } else if let readingLabel = reading?.positionLabel {
            positionLabel = readingLabel
        } else if meters != nil {
            positionLabel = nil
        } else if let progress, progress.unit == .second, progress.total > 0 {
            positionLabel =
                "Current · \(DurationPresentation.progress(Double(progress.index))) of \(DurationPresentation.progress(Double(progress.total)))"
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
        self.actions = actions
        separateExplanation = separate?.explanation
        separateMeters = meters
    }
}
