import Foundation

/// Focused reading use case for Entity Detail. It owns no presentation state;
/// the page's `EntityDetailReadingState` accepts only current outcomes.
@MainActor
struct EntityDetailReadingService {
    private let reader: (any BookReaderServicing)?

    init(reader: (any BookReaderServicing)?) {
        self.reader = reader
    }

    var isAvailable: Bool {
        reader != nil
    }

    func load(detail: EntityDetail) async -> EntityDetailReadingLoadOutcome {
        guard supportsReading(detail), let reader else { return .unavailable }

        return await resolve(detail: detail, reader: reader)
    }

    func reload(detailID: UUID, kind: EntityKind) async -> EntityDetailReadingLoadOutcome {
        guard let reader else { return .unavailable }

        do {
            let detail = try await reader.loadEntity(id: detailID, kind: kind)
            guard !Task.isCancelled else { return .cancelled }
            return await resolve(detail: detail, reader: reader)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    func startOver(
        detail: EntityDetail,
        readerMode: ReaderMode
    ) async -> EntityDetailReadingMutationOutcome {
        guard supportsReading(detail), let reader else { return .unavailable }

        do {
            if isSingleFile(detail) {
                let refreshedDetail = try await reader.loadEntity(id: detail.id, kind: detail.kind)
                guard let progress = progress(in: refreshedDetail), progress.total > 0 else {
                    return .failure("Reading progress is unavailable.")
                }
                try await reader.updateReadingProgress(
                    id: detail.id,
                    request: EntityProgressUpdateRequest(
                        currentEntityID: detail.id,
                        unit: progress.unit,
                        index: 0,
                        total: progress.total,
                        mode: progress.mode ?? readerMode,
                        completed: nil,
                        reset: true,
                        location: nil
                    )
                )
                return await refreshedContent(detailID: detail.id, kind: detail.kind, reader: reader)
            }

            let start = try await BookReaderManifestResolver(loader: reader).resolve(
                selected: detail,
                command: .read
            )
            guard let position = start.position(at: 0) else {
                return .failure(BookReaderManifestError.noReadablePages.localizedDescription)
            }
            try await reader.updateReadingProgress(
                id: start.bookID,
                request: EntityProgressUpdateRequest(
                    currentEntityID: position.chapterID,
                    unit: .page,
                    index: 0,
                    total: position.pageCount,
                    mode: readerMode,
                    completed: nil,
                    reset: true
                )
            )
            return await refreshedContent(detailID: detail.id, kind: detail.kind, reader: reader)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    func toggleCompletion(
        detail: EntityDetail,
        manifest: BookReaderManifest,
        status: MediaProgressStatus
    ) async -> EntityDetailReadingMutationOutcome {
        guard let reader else { return .unavailable }
        guard let progress = manifest.progress,
            let chapterID = progress.currentEntityID
        else {
            return .failure("Reading progress is unavailable.")
        }

        do {
            try await reader.updateReadingProgress(
                id: manifest.bookID,
                request: EntityProgressUpdateRequest(
                    currentEntityID: chapterID,
                    unit: progress.unit,
                    index: progress.index,
                    total: progress.total,
                    mode: progress.mode,
                    completed: status != .completed,
                    reset: false,
                    location: progress.location
                )
            )
            return await refreshedContent(detailID: detail.id, kind: detail.kind, reader: reader)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    private func refreshedContent(
        detailID: UUID,
        kind: EntityKind,
        reader: any BookReaderServicing
    ) async -> EntityDetailReadingMutationOutcome {
        do {
            let refreshedDetail = try await reader.loadEntity(id: detailID, kind: kind)
            if isSingleFile(refreshedDetail) {
                guard !Task.isCancelled else { return .cancelled }
                return .singleFile(refreshedDetail)
            }
            let manifest = try await BookReaderManifestResolver(loader: reader).resolve(
                selected: refreshedDetail,
                command: .resume
            )
            guard !Task.isCancelled else { return .cancelled }
            return .content(manifest)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    private func resolve(
        detail: EntityDetail,
        reader: any BookReaderServicing
    ) async -> EntityDetailReadingLoadOutcome {
        guard supportsReading(detail) else { return .unavailable }

        do {
            if isSingleFile(detail) {
                guard !Task.isCancelled else { return .cancelled }
                return .singleFile(detail)
            }
            let manifest = try await BookReaderManifestResolver(loader: reader).resolve(
                selected: detail,
                command: .resume
            )
            guard !Task.isCancelled else { return .cancelled }
            return .content(manifest)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    private func supportsReading(_ detail: EntityDetail) -> Bool {
        guard [.book, .bookVolume, .bookChapter].contains(detail.kind) else { return false }
        guard detail.kind == .book else { return true }
        switch BookReaderFormatPolicy.route(for: detail.bookFormat) {
        case .comic, .pdf, .epub:
            return true
        case .unavailable, .unsupported:
            return false
        }
    }

    private func isSingleFile(_ detail: EntityDetail) -> Bool {
        guard detail.kind == .book else { return false }
        switch BookReaderFormatPolicy.route(for: detail.bookFormat) {
        case .pdf, .epub:
            return true
        case .unavailable, .comic, .unsupported:
            return false
        }
    }

    private func progress(in detail: EntityDetail) -> EntityProgressCapability? {
        detail.capability()
    }
}
