import Foundation

struct EntityDetailSectionSupport {
    let ownerLink: EntityLink?
    let canEditMetadata: Bool
    let acquisitionService: (any EntityAcquisitionServicing)?
    let requestActivityService: (any RequestActivityServicing)?
    let transcriptSourceLoader: (any EntityTranscriptSourceLoading)?
    let chapterMapping: BookChapterMappingEditorPresentation?
    let onAcquisitionMutated: @MainActor () async -> Void
    let onEntityPruned: @MainActor () -> Void
    let onEnterReleaseDate: @MainActor @Sendable () -> Void
    let onSaveChapterMappings: @MainActor ([BookChapterAudioMapping]) async throws -> [BookChapterAudioMapping]

    init(
        ownerLink: EntityLink? = nil,
        canEditMetadata: Bool = false,
        acquisitionService: (any EntityAcquisitionServicing)? = nil,
        requestActivityService: (any RequestActivityServicing)? = nil,
        transcriptSourceLoader: (any EntityTranscriptSourceLoading)? = nil,
        chapterMapping: BookChapterMappingEditorPresentation? = nil,
        onAcquisitionMutated: @escaping @MainActor () async -> Void = {},
        onEntityPruned: @escaping @MainActor () -> Void = {},
        onEnterReleaseDate: @escaping @MainActor @Sendable () -> Void = {},
        onSaveChapterMappings: @escaping @MainActor ([BookChapterAudioMapping]) async throws
            -> [BookChapterAudioMapping] = { _ in [] }
    ) {
        self.ownerLink = ownerLink
        self.canEditMetadata = canEditMetadata
        self.acquisitionService = acquisitionService
        self.requestActivityService = requestActivityService
        self.transcriptSourceLoader = transcriptSourceLoader
        self.chapterMapping = chapterMapping
        self.onAcquisitionMutated = onAcquisitionMutated
        self.onEntityPruned = onEntityPruned
        self.onEnterReleaseDate = onEnterReleaseDate
        self.onSaveChapterMappings = onSaveChapterMappings
    }

    init(
        ownerLink: EntityLink,
        dependencies: EntityDetailDependencies,
        onAcquisitionMutated: @escaping @MainActor () async -> Void,
        onEntityPruned: @escaping @MainActor () -> Void,
        onEnterReleaseDate: @escaping @MainActor @Sendable () -> Void = {},
        chapterMapping: BookChapterMappingEditorPresentation? = nil,
        onSaveChapterMappings: @escaping @MainActor ([BookChapterAudioMapping]) async throws
            -> [BookChapterAudioMapping] = { _ in [] }
    ) {
        self.init(
            ownerLink: ownerLink,
            canEditMetadata: dependencies.metadataMutator != nil,
            acquisitionService: dependencies.acquisitionService,
            requestActivityService: dependencies.requestActivityService,
            transcriptSourceLoader: dependencies.transcriptSourceLoader,
            chapterMapping: chapterMapping,
            onAcquisitionMutated: onAcquisitionMutated,
            onEntityPruned: onEntityPruned,
            onEnterReleaseDate: onEnterReleaseDate,
            onSaveChapterMappings: onSaveChapterMappings
        )
    }
}
