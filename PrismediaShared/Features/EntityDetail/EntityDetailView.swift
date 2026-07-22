import SwiftUI

/// Generic native detail coordinator for every Prismedia entity kind.
public struct EntityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.videoPlaybackSession) var videoPlaybackSession
    #if os(iOS) || os(macOS)
        @Environment(MusicPlayerController.self) var musicPlayer
        @State var pendingCombinedPlaybackTask: Task<Void, Never>?
    #endif
    @State var state = EntityDetailState()
    @State var videoPlaybackPreparation = VideoPlaybackPreparationCoordinator()
    @State var selectedSection: EntityDetailSectionID = .details
    @State var advancedEntityLink: EntityLink?
    @State var thumbnailPlaybackLink: EntityLink?
    @State var suppressesRoutePlayback = false
    @State var readerPresentation: EntityReaderPresentation?
    @State var readingState = EntityDetailReadingState()
    @State var collectionMembersState = CollectionMembersState()
    @State var audiobookProjection: AudiobookPlaybackProjection?
    @State var isAudiobookLoading = false
    @State var isListeningMutating = false
    @State var audiobookErrorMessage: String?
    @State var readableBookChapters: [ReadableBookChapter] = []
    @State var currentReadableChapterID: String?
    @State var areBookChaptersLoading = false
    @State var bookChaptersErrorMessage: String?
    @State var mappedBookChapters: [BookChapterMapping] = []
    @State var videoProgressEpisode: EntityDetail?
    @State var isVideoProgressMutating = false
    @State var videoProgressErrorMessage: String?
    @State var artworkPalette: ArtworkPalette?
    @State var editPresentation: EntityDetailEditPresentation?
    @State var collectionSheetPresented = false

    let link: EntityLink
    let dependencies: EntityDetailDependencies
    let imageViewerSession: EntityImageViewerSession?
    let service: EntityDetailService
    let readingService: EntityDetailReadingService
    let collectionMembersService: CollectionMembersService
    let videoProgressService: VideoContainerProgressService

    public init(
        link: EntityLink,
        dependencies: EntityDetailDependencies,
        imageViewerSession: EntityImageViewerSession? = nil
    ) {
        self.link = link
        self.dependencies = dependencies
        self.imageViewerSession = imageViewerSession
        service = EntityDetailService(
            loader: dependencies.detailLoader,
            mutator: dependencies.mutator
        )
        readingService = EntityDetailReadingService(reader: dependencies.readerService)
        collectionMembersService = CollectionMembersService(
            loader: dependencies.collectionItemsLoader
        )
        videoProgressService = VideoContainerProgressService(
            loader: dependencies.detailLoader,
            mutator: dependencies.progressMutator
        )
    }

    public var body: some View {
        Group {
            switch state.phase {
            case .loading:
                EntityDetailPlatformLoadingView(link: link)
            case .content(let detail):
                detailView(detail)
            case .failure(let message):
                failureView(message)
            }
        }
        .prismediaScreenBackground()
        .modifier(
            EntityDetailPlatformPresentationModifier(
                navigationTitle: navigationTitle,
                detail: currentDetail,
                presentation: currentPresentation,
                editPresentation: $editPresentation,
                collectionSheetPresented: $collectionSheetPresented,
                isActionSupported: isSupported,
                isActionEnabled: isEnabled,
                actionLabel: accessibilityLabel,
                actionHint: accessibilityHint,
                onAction: perform,
                editContent: editSheet
            )
        )
        .task(id: link) {
            videoPlaybackPreparation.reset()
            await loadDetail()
        }
        .onDisappear {
            videoPlaybackPreparation.reset()
            #if !os(tvOS)
                videoPlaybackSession?.ownerDidDisappear(link)
            #endif
        }
        .prismediaEntityDestination(
            item: $advancedEntityLink,
            dependencies: dependencies
        )
        .prismediaReaderCover(item: $readerPresentation) { presentation in
            if let service = dependencies.readerService {
                EntityReaderView(
                    selected: presentation.detail,
                    command: presentation.command,
                    service: service,
                    bookmarkStore: dependencies.readerBookmarkStore,
                    locatorStore: dependencies.readerLocatorStore,
                    initialEPUBLocation: presentation.initialEPUBLocation,
                    initialEPUBProgression: presentation.initialEPUBProgression,
                    companionPlayer: companionPlayer(for: presentation),
                    findCurrentAudiobookReadingTarget: {
                        #if os(iOS) || os(macOS)
                            currentAudiobookReadingTarget(for: presentation.detail)
                        #else
                            nil
                        #endif
                    },
                    onEPUBReady: {
                        #if os(iOS) || os(macOS)
                            beginCombinedPlayback(for: presentation)
                        #endif
                    }
                )
                .environment(
                    \.artworkPrimaryAccent,
                    artworkPalette?.primary.color ?? PrismediaColor.accent
                )
            }
        }
        .onChange(of: readerPresentation) { previous, current in
            #if os(iOS) || os(macOS)
                if current == nil {
                    pendingCombinedPlaybackTask?.cancel()
                    pendingCombinedPlaybackTask = nil
                }
            #endif
            guard previous != nil, current == nil else { return }
            pauseCompanionAudiobook(for: previous)
            Task {
                await reloadReadingState()
                if case .singleFile(let refreshedDetail) = readingState.phase {
                    await loadBookChapters(for: refreshedDetail)
                }
            }
        }
        #if os(iOS) || os(macOS)
            .onChange(of: musicPlayer.currentTrack?.id) {
                guard case .content(let detail) = state.phase else { return }
                refreshBookChapterMappings(for: detail)
            }
        #endif
        .alert("Couldn’t Update Details", isPresented: mutationErrorPresented) {
            Button("OK") { state.dismissMutationError() }
        } message: {
            Text(state.mutationErrorMessage ?? "Please try again.")
        }
    }

    var navigationTitle: String {
        currentDetail?.title ?? link.thumbnailPreview?.title ?? ""
    }

    var currentDetail: EntityDetail? {
        guard case .content(let detail) = state.phase else { return nil }
        return detail
    }

    var currentPresentation: EntityDetailPresentation? {
        currentDetail.map {
            EntityDetailPresentation(
                detail: $0,
                canEditMetadata: dependencies.metadataMutator != nil
            )
        }
    }

    var mutationErrorPresented: Binding<Bool> {
        Binding(
            get: { state.mutationErrorMessage != nil },
            set: { isPresented in
                if !isPresented { state.dismissMutationError() }
            }
        )
    }
}

#if DEBUG
    #Preview("Entity Detail · Native") {
        let detail = EntityDetailPreviewFixture.detail
        let detailLoader = PreviewEntityDetailLoader(detail: detail)
        let dependencies = EntityDetailDependencies(
            detailLoader: detailLoader,
            mutator: nil,
            collectionItemsLoader: nil,
            readerService: nil,
            videoPlaybackService: VideoPlaybackPreviewService(),
            onEntityMutated: {}
        )

        PreviewShell(signedIn: true) {
            NavigationStack {
                EntityDetailView(
                    link: EntityLink(entityID: detail.id, kind: detail.kind),
                    dependencies: dependencies
                )
                .prismediaEntityDestinations(dependencies: dependencies)
            }
        }
    }
#endif
