import Foundation

/// Value state owned by `EntityDetailView` for its independent reading surface.
/// Request generations prevent an older entity or mutation response from
/// replacing the currently rendered reading state.
struct EntityDetailReadingState: Hashable, Sendable {
    private(set) var phase: EntityDetailReadingPhase = .idle
    private(set) var isMutating = false
    private(set) var errorMessage: String?

    private var entityID: UUID?
    private var generation = 0

    var manifest: BookReaderManifest? {
        switch phase {
        case .content(let manifest):
            return manifest
        case .singleFile(let detail):
            return singleFileManifest(detail)
        case .idle, .loading, .failure:
            return nil
        }
    }

    var progressPresentation: ReadingProgressPresentation? {
        switch phase {
        case .content(let manifest):
            return ReadingProgressPresentation(
                progress: manifest.progress,
                chapters: manifest.chapters.map(\.summary)
            )
        case .singleFile(let detail):
            let progress = detail.capabilities.lazy.compactMap { capability -> EntityProgressCapability? in
                guard case .progress(let value) = capability else { return nil }
                return value
            }.first
            return ReadingProgressPresentation(singleFileProgress: progress)
        case .idle, .loading, .failure:
            return nil
        }
    }

    @discardableResult
    mutating func beginLoad(entityID: UUID) -> EntityDetailReadingRequest {
        let request = nextRequest(entityID: entityID)
        self.entityID = entityID
        phase = .loading
        isMutating = false
        errorMessage = nil
        return request
    }

    mutating func finishLoad(
        _ outcome: EntityDetailReadingLoadOutcome,
        request: EntityDetailReadingRequest
    ) {
        guard isCurrent(request) else { return }

        switch outcome {
        case .content(let manifest):
            phase = .content(manifest)
        case .singleFile(let detail):
            phase = .singleFile(detail)
        case .failure(let message):
            phase = .failure(message)
        case .cancelled, .unavailable:
            phase = .idle
        }
    }

    mutating func beginMutation() -> EntityDetailReadingRequest? {
        guard !isMutating, manifest != nil, let entityID else { return nil }
        let request = nextRequest(entityID: entityID)
        isMutating = true
        errorMessage = nil
        return request
    }

    @discardableResult
    mutating func finishMutation(
        _ outcome: EntityDetailReadingMutationOutcome,
        request: EntityDetailReadingRequest
    ) -> Bool {
        guard isCurrent(request) else { return false }
        isMutating = false

        switch outcome {
        case .content(let manifest):
            phase = .content(manifest)
            return true
        case .singleFile(let detail):
            phase = .singleFile(detail)
            return true
        case .failure(let message):
            errorMessage = message
            return false
        case .cancelled:
            return false
        case .unavailable:
            errorMessage = "Reading progress is unavailable."
            return false
        }
    }

    mutating func dismissError() {
        errorMessage = nil
    }

    mutating func reset() {
        generation += 1
        entityID = nil
        phase = .idle
        isMutating = false
        errorMessage = nil
    }

    func primaryActions(
        fallback: [EntityDetailAction],
        entityKind: EntityKind
    ) -> [EntityDetailAction] {
        guard let completed = readingIsCompleted else { return fallback }

        let suffix: String
        switch entityKind {
        case .bookVolume: suffix = " Volume"
        case .bookChapter: suffix = " Chapter"
        default: suffix = ""
        }

        if completed {
            return [
                EntityDetailAction(
                    id: .read,
                    title: "Re-read\(suffix)",
                    systemImage: "book.fill",
                    isSelected: false,
                    isPrimary: true
                )
            ]
        }

        return [
            EntityDetailAction(
                id: .resume,
                title: "Resume\(suffix)",
                systemImage: "book.pages",
                isSelected: false,
                isPrimary: true
            )
        ]
    }

    var requiresResetBeforeReading: Bool {
        readingIsCompleted == true
    }

    private var readingIsCompleted: Bool? {
        guard let manifest,
            let progress = manifest.progress,
            let currentEntityID = progress.currentEntityID
        else { return nil }

        switch phase {
        case .content:
            guard manifest.chapters.contains(where: { $0.id == currentEntityID }) else {
                return nil
            }
            return progress.completedAt != nil
        case .singleFile:
            return ReadingProgressPresentation(singleFileProgress: progress)?.status == .completed
        case .idle, .loading, .failure:
            return nil
        }
    }

    private mutating func nextRequest(entityID: UUID) -> EntityDetailReadingRequest {
        generation += 1
        return EntityDetailReadingRequest(entityID: entityID, generation: generation)
    }

    private func isCurrent(_ request: EntityDetailReadingRequest) -> Bool {
        request.entityID == entityID && request.generation == generation
    }

    private func singleFileManifest(_ detail: EntityDetail) -> BookReaderManifest {
        let progress = detail.capabilities.lazy.compactMap { capability -> EntityProgressCapability? in
            guard case .progress(let value) = capability else { return nil }
            return value
        }.first
        let defaultMode: ReaderMode = detail.bookFormat == .pdf ? .scrolled : .paged
        return BookReaderManifest(
            bookID: detail.id,
            title: detail.title,
            chapters: [],
            nextChapter: nil,
            progress: progress,
            initialIndex: 0,
            readerMode: progress?.mode ?? defaultMode
        )
    }
}
