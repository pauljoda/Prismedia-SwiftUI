import Foundation

public struct ReadingProgressPresentation: Hashable, Sendable {
    public let status: MediaProgressStatus
    public let percent: Int
    public let positionLabel: String?
    public let contextLabel: String?
    public let canResume: Bool
    public let canStartOver: Bool
    public let readerMode: ReaderMode

    public init?(progress: EntityProgressCapability?, chapters: [BookChapterSummary]) {
        guard let progress,
            let chapterID = progress.currentEntityID,
            let chapter = chapters.first(where: { $0.id == chapterID })
        else { return nil }

        let pageCount = max(0, chapter.pageCount > 0 ? chapter.pageCount : progress.total)
        guard pageCount > 0 else { return nil }
        let localIndex = max(0, progress.index)
        let workTotal = max(0, progress.workTotal ?? progress.total)
        let workIndex = max(0, progress.workIndex ?? localIndex)
        let workPage = workTotal > 0 ? min(workIndex + 1, workTotal) : min(localIndex + 1, pageCount)
        let rawPercent =
            workTotal > 0
            ? Int((Double(min(workIndex, workTotal - 1) + 1) / Double(workTotal) * 100).rounded())
            : Int((Double(min(localIndex, pageCount - 1) + 1) / Double(pageCount) * 100).rounded())
        let completed = progress.completedAt != nil || rawPercent >= 100

        status = completed ? .completed : .inProgress
        percent = completed ? 100 : min(100, max(workPage > 0 ? 1 : 0, rawPercent))
        positionLabel = completed ? nil : "Book page \(workPage) of \(workTotal > 0 ? workTotal : pageCount)"
        contextLabel = "Ch. \(chapter.sortOrder + 1): \(chapter.title)"
        canResume = !completed
        canStartOver = true
        readerMode = progress.mode == .webtoon ? .webtoon : .paged
    }

    public init?(singleFileProgress progress: EntityProgressCapability?) {
        guard let progress, progress.currentEntityID != nil, progress.total > 0 else { return nil }

        let total = progress.total
        let index = max(0, progress.index)
        let usesPages = progress.unit == .page
        let rawPercent =
            usesPages
            ? Int((Double(min(index, total - 1) + 1) / Double(total) * 100).rounded())
            : Int((Double(min(index, total)) / Double(total) * 100).rounded())
        let completed = progress.completedAt != nil || rawPercent >= 100
        let percent = completed ? 100 : min(100, max(rawPercent > 0 ? 1 : 0, rawPercent))

        status = completed ? .completed : .inProgress
        self.percent = percent
        positionLabel =
            completed
            ? nil
            : usesPages
                ? "Page \(min(index + 1, total)) of \(total)"
                : "\(percent)% read"
        contextLabel = nil
        canResume = !completed
        canStartOver = true
        readerMode = progress.mode ?? (usesPages ? .scrolled : .paged)
    }
}
