import SwiftUI

/// Generic native detail coordinator for every Prismedia entity kind.
public struct EntityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @Environment(PrismediaAppRouter.self) var router
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
    @State var videoPlaybackStartOverrideSeconds: Double?
    @State var suppressesRoutePlayback = false
    @State var isVideoFullscreenLaunchActive: Bool
    @State var pendingVideoPlaybackActionID: EntityDetailActionID?
    @State var readerPresentation: EntityReaderPresentation?
    @State var readingState = EntityDetailReadingState()
    @State var collectionMembersState = CollectionMembersState()
    @State var audiobookProjection: AudiobookPlaybackProjection?
    @State var isAudiobookLoading = false
    @State var isListeningMutating = false
    @State var audiobookErrorMessage: String?
    @State var readableBookChapters: [ReadableBookChapter] = []
    @State var epubReadingProgressRanges: [EPUBReadingProgressRange] = []
    @State var areBookChaptersLoading = false
    @State var bookChaptersErrorMessage: String?
    @State var mappedBookChapters: [BookChapterMapping] = []
    @State var bookProgressLoadingState = BookProgressLoadingState()
    @State var videoProgressEpisode: EntityDetail?
    @State var liveVideoResumeSeconds: Double?
    @State var resolvedVideoTechnicalDetail: EntityDetail?
    @State var isVideoProgressMutating = false
    @State var videoProgressErrorMessage: String?
    @State var artworkPalette: ArtworkPalette?
    @State var acquisitionStatus: AcquisitionStatus?
    @State var editPresentation: EntityDetailEditPresentation?
    @State var collectionSheetPresented = false
    @State var consumptionReporter: EntityConsumptionReporter
    #if os(iOS) || os(macOS)
        @State var identifyAvailability = EntityIdentifyAvailability.checking
        @State var identifyPresentation: IdentifyEntryPresentation?
        @State var identifyEntryTask: Task<Void, Never>?
    #endif

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
        #if os(iOS)
            _isVideoFullscreenLaunchActive = State(initialValue: link.intent == .playback)
        #else
            _isVideoFullscreenLaunchActive = State(initialValue: false)
        #endif
        _pendingVideoPlaybackActionID = State(initialValue: nil)
        _consumptionReporter = State(
            initialValue: EntityConsumptionReporter(service: dependencies.consumptionService)
        )
        #if os(iOS) || os(macOS)
            _acquisitionStatus = State(
                initialValue: link.sourceThumbnail?.wantedStatus
                    ?? link.sourceThumbnail?.latestAcquisitionStatus
            )
        #else
            _acquisitionStatus = State(initialValue: nil)
        #endif
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
        #if os(iOS) || os(macOS)
            .sheet(
                item: $identifyPresentation,
                onDismiss: {
                    Task {
                        guard let detail = currentDetail else { return }
                        await refreshIdentifyAvailability(for: detail)
                    }
                }
            ) { presentation in
                EntityIdentifyFlowView(
                    session: presentation.session,
                    entityID: presentation.entityID,
                    automaticallyBegins: false,
                    onIdentified: {
                        await loadDetail()
                        dependencies.onEntityMutated()
                    }
                )
                .environment(\.artworkPalette, artworkPalette)
                .environment(
                    \.artworkPrimaryAccent,
                    artworkPalette?.primary.color ?? PrismediaColor.accent
                )
            }
        #endif
        .task(id: link) {
            await loadDetailIfNeeded()
            #if os(iOS) || os(macOS)
                await refreshAcquisitionStatus()
            #endif
            if link.intent == .editReleaseDate {
                presentReleaseDateEditor()
            }
        }
        .task(id: galleryConsumptionID) {
            guard let galleryConsumptionID else {
                consumptionReporter.close()
                await consumptionReporter.flush()
                return
            }
            consumptionReporter.open(
                id: galleryConsumptionID,
                active: scenePhase == .active
            )
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    break
                }
                consumptionReporter.heartbeat()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard galleryConsumptionID != nil else { return }
            if phase == .active {
                consumptionReporter.resume()
            } else {
                consumptionReporter.pause()
            }
        }
        .onDisappear {
            consumptionReporter.close()
            Task { await consumptionReporter.flush() }
        }
        .onDisappear {
            // Presenting this page's own fullscreen player removes the presenting
            // hierarchy on iOS, so this fires while the player is up. Tearing
            // playback down here would collapse the view that owns the fullscreen
            // presentation and dismiss the player one frame after it opened.
            #if os(iOS)
                guard !isVideoFullscreenLaunchActive,
                    !videoPlaybackPreparation.isFullscreenPresented
                else { return }
            #endif
            videoPlaybackPreparation.reset()
            #if !os(tvOS)
                videoPlaybackSession?.ownerDidDisappear(link)
            #endif
        }
        .onChange(of: videoPlaybackPreparation.phase) { _, phase in
            switch phase {
            case .ready, .failure:
                pendingVideoPlaybackActionID = nil
            case .idle, .loading:
                break
            }
        }
        #if !os(iOS)
            .prismediaEntityDestination(
                item: $advancedEntityLink,
                dependencies: dependencies
            )
        #endif
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
                    epubProgressRanges: epubReadingProgressRanges,
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
                .environment(\.artworkPalette, artworkPalette)
                .environment(
                    \.artworkPrimaryAccent,
                    artworkPalette?.primary.color ?? PrismediaColor.accent
                )
                .environment(
                    \.artworkSecondaryText,
                    artworkPalette?.secondary.color ?? PrismediaColor.textSecondary
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
            Task {
                await finishCompanionAudiobookPlayback(for: previous)
                await refreshBookProgressAfterReader()
            }
        }
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

    var galleryConsumptionID: UUID? {
        guard currentDetail?.kind == .gallery else { return nil }
        return currentDetail?.id
    }

    var currentPresentation: EntityDetailPresentation? {
        currentDetail.map {
            EntityDetailPresentation(
                detail: $0,
                canEditMetadata: dependencies.metadataMutator != nil,
                identifyActionLabel: identifyActionLabel,
                identifyActionSystemImage: identifyActionSystemImage,
                acquisitionStatus: acquisitionStatus,
                mediaDetail: resolvedVideoTechnicalDetail,
                mediaThumbnail: link.sourceThumbnail
            )
        }
    }

    var identifyActionLabel: String {
        #if os(iOS) || os(macOS)
            identifyAvailability.actionLabel
        #else
            "Identify"
        #endif
    }

    var identifyActionSystemImage: String {
        #if os(iOS) || os(macOS)
            identifyAvailability.actionSystemImage
        #else
            "doc.viewfinder"
        #endif
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
