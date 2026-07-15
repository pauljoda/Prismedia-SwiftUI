import Foundation

/// Immutable feature composition for Entity Detail.
///
/// Each capability is explicit so decorators and preview services can be
/// supplied independently without relying on runtime protocol casts.
public struct EntityDetailDependencies: Sendable {
    public let detailLoader: any EntityDetailLoading
    public let mutator: (any EntityDetailMutating)?
    public let metadataMutator: (any EntityMetadataMutating)?
    public let collectionItemsLoader: (any CollectionItemsLoading)?
    public let entityGridLoader: (any EntityGridLoading)?
    public let readerService: (any BookReaderServicing)?
    public let readerBookmarkStore: any EPUBBookmarkStoring
    public let readerLocatorStore: EPUBLocatorStore
    public let videoPlaybackService: (any VideoPlaybackServicing)?
    public let audioPlaybackService: (any MusicPlaybackServicing)?
    public let onEntityMutated: @MainActor @Sendable () -> Void
    public let acquisitionService: (any EntityAcquisitionServicing)?
    public let imageSourceLoader: (any EntityImageSourceLoading)?
    public let imageVideoAspectRatioLoader: (any EntityImageVideoAspectRatioLoading)?
    public let mediaSequenceLoader: (any EntityMediaSequenceLoading)?
    public let transcriptSourceLoader: (any EntityTranscriptSourceLoading)?
    public let trickplayFrameLoader: (any TrickplayFrameLoading)?

    public init(
        detailLoader: any EntityDetailLoading,
        mutator: (any EntityDetailMutating)?,
        collectionItemsLoader: (any CollectionItemsLoading)?,
        readerService: (any BookReaderServicing)?,
        videoPlaybackService: (any VideoPlaybackServicing)?,
        onEntityMutated: @escaping @MainActor @Sendable () -> Void,
        audioPlaybackService: (any MusicPlaybackServicing)? = nil,
        acquisitionService: (any EntityAcquisitionServicing)? = nil,
        imageSourceLoader: (any EntityImageSourceLoading)? = nil,
        imageVideoAspectRatioLoader: (any EntityImageVideoAspectRatioLoading)? = nil,
        mediaSequenceLoader: (any EntityMediaSequenceLoading)? = nil,
        transcriptSourceLoader: (any EntityTranscriptSourceLoading)? = nil,
        trickplayFrameLoader: (any TrickplayFrameLoading)? = nil,
        entityGridLoader: (any EntityGridLoading)? = nil,
        metadataMutator: (any EntityMetadataMutating)? = nil,
        readerBookmarkStore: any EPUBBookmarkStoring = EPUBBookmarkStore.disabled,
        readerLocatorStore: EPUBLocatorStore = .disabled
    ) {
        self.detailLoader = detailLoader
        self.mutator = mutator
        self.metadataMutator = metadataMutator
        self.collectionItemsLoader = collectionItemsLoader
        self.entityGridLoader = entityGridLoader
        self.readerService = readerService
        self.readerBookmarkStore = readerBookmarkStore
        self.readerLocatorStore = readerLocatorStore
        self.videoPlaybackService = videoPlaybackService
        self.audioPlaybackService = audioPlaybackService
        self.onEntityMutated = onEntityMutated
        self.acquisitionService = acquisitionService
        self.imageSourceLoader = imageSourceLoader
        self.imageVideoAspectRatioLoader = imageVideoAspectRatioLoader
        self.mediaSequenceLoader = mediaSequenceLoader
        self.transcriptSourceLoader = transcriptSourceLoader
        self.trickplayFrameLoader = trickplayFrameLoader
    }
}
