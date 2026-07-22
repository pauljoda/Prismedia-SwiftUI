import Foundation

struct EntityDetailSectionSupport {
    let ownerLink: EntityLink?
    let canEditMetadata: Bool
    let acquisitionService: (any EntityAcquisitionServicing)?
    let requestActivityService: (any RequestActivityServicing)?
    let transcriptSourceLoader: (any EntityTranscriptSourceLoading)?
    let onAcquisitionMutated: @MainActor () async -> Void
    let onEntityPruned: @MainActor () -> Void

    init(
        ownerLink: EntityLink? = nil,
        canEditMetadata: Bool = false,
        acquisitionService: (any EntityAcquisitionServicing)? = nil,
        requestActivityService: (any RequestActivityServicing)? = nil,
        transcriptSourceLoader: (any EntityTranscriptSourceLoading)? = nil,
        onAcquisitionMutated: @escaping @MainActor () async -> Void = {},
        onEntityPruned: @escaping @MainActor () -> Void = {}
    ) {
        self.ownerLink = ownerLink
        self.canEditMetadata = canEditMetadata
        self.acquisitionService = acquisitionService
        self.requestActivityService = requestActivityService
        self.transcriptSourceLoader = transcriptSourceLoader
        self.onAcquisitionMutated = onAcquisitionMutated
        self.onEntityPruned = onEntityPruned
    }

    init(
        ownerLink: EntityLink,
        dependencies: EntityDetailDependencies,
        onAcquisitionMutated: @escaping @MainActor () async -> Void,
        onEntityPruned: @escaping @MainActor () -> Void
    ) {
        self.init(
            ownerLink: ownerLink,
            canEditMetadata: dependencies.metadataMutator != nil,
            acquisitionService: dependencies.acquisitionService,
            requestActivityService: dependencies.requestActivityService,
            transcriptSourceLoader: dependencies.transcriptSourceLoader,
            onAcquisitionMutated: onAcquisitionMutated,
            onEntityPruned: onEntityPruned
        )
    }
}
