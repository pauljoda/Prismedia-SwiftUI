import Foundation
import ImageIO
import Observation

/// Orchestrates reader I/O while leaving presentation state in `ComicReaderView`.
@MainActor
public struct BookReaderUseCase: Sendable {
    private let selected: EntityDetail
    private let command: BookReaderCommand
    private let service: any BookReaderServicing

    public init(
        selected: EntityDetail,
        command: BookReaderCommand,
        service: any BookReaderServicing
    ) {
        self.selected = selected
        self.command = command
        self.service = service
    }

    public func loadManifest() async throws -> BookReaderManifest {
        try await resolve(selected: selected, command: command)
    }

    public func loadFollowingManifest(chapterID: UUID) async throws -> BookReaderManifest {
        try await loadChapterManifest(chapterID: chapterID, command: .resume)
    }

    public func loadChapterManifest(
        chapterID: UUID,
        command: BookReaderCommand
    ) async throws -> BookReaderManifest {
        let chapter = try await service.loadEntity(id: chapterID)
        return try await resolve(selected: chapter, command: command)
    }

    public func progressRequest(
        in manifest: BookReaderManifest,
        index: Int,
        mode: ReaderMode,
        completed explicitCompletion: Bool? = nil,
        reset: Bool = false,
        allowAutomaticCompletion: Bool = true
    ) -> EntityProgressUpdateRequest? {
        let pageIndex = min(index, max(0, manifest.pages.count - 1))
        guard let position = manifest.position(at: pageIndex) else { return nil }

        let reachedBookEnd = index >= manifest.pages.count - 1 && manifest.nextChapter == nil
        let completed =
            explicitCompletion
            ?? (allowAutomaticCompletion && reachedBookEnd ? true : nil)

        return EntityProgressUpdateRequest(
            currentEntityID: position.chapterID,
            unit: .page,
            index: position.pageIndex,
            total: position.pageCount,
            mode: mode,
            completed: completed,
            reset: reset
        )
    }

    private func resolve(
        selected: EntityDetail,
        command: BookReaderCommand
    ) async throws -> BookReaderManifest {
        try await BookReaderManifestResolver(loader: service).resolve(
            selected: selected,
            command: command
        )
    }
}
