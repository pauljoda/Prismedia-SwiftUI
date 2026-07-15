import SwiftUI

/// Generic native detail surface for every Prismedia entity kind.
public struct EntityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.videoPlaybackSession) private var videoPlaybackSession
    #if os(iOS) || os(macOS)
        @Environment(MusicPlayerController.self) private var musicPlayer
        @State private var pendingCombinedPlaybackTask: Task<Void, Never>?
    #endif
    @State private var state = EntityDetailState()
    @State private var videoPlaybackPreparation = VideoPlaybackPreparationCoordinator()
    @State private var selectedSection: EntityDetailSectionID = .details
    @State private var advancedEntityLink: EntityLink?
    @State private var thumbnailPlaybackLink: EntityLink?
    @State private var suppressesRoutePlayback = false
    @State private var readerPresentation: EntityReaderPresentation?
    @State private var readingState = EntityDetailReadingState()
    @State private var collectionMembersState = CollectionMembersState()
    @State private var audiobookProjection: AudiobookPlaybackProjection?
    @State private var isAudiobookLoading = false
    @State private var isListeningMutating = false
    @State private var audiobookErrorMessage: String?
    @State private var readableBookChapters: [ReadableBookChapter] = []
    @State private var currentReadableChapterID: String?
    @State private var areBookChaptersLoading = false
    @State private var bookChaptersErrorMessage: String?
    @State private var mappedBookChapters: [BookChapterMapping] = []
    @State private var artworkPalette: ArtworkPalette?
    @State private var editPresentation: EntityDetailEditPresentation?
    #if os(iOS)
        @State private var collectionSheetPresented = false
    #endif
    private let link: EntityLink
    private let dependencies: EntityDetailDependencies
    private let imageViewerSession: EntityImageViewerSession?
    private let service: EntityDetailService
    private let readingService: EntityDetailReadingService
    private let collectionMembersService: CollectionMembersService

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
    }

    public var body: some View {
        Group {
            switch state.phase {
            case .loading:
                loadingView
            case .content(let detail):
                detailView(detail)
            case .failure(let message):
                failureView(message)
            }
        }
        .prismediaScreenBackground()
        #if !os(tvOS)
            .navigationTitle(navigationTitle)
            .prismediaInlineNavigationTitle()
        #endif
        #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if case .content(let detail) = state.phase {
                    ToolbarItem(placement: .primaryAction) {
                        let presentation = EntityDetailPresentation(
                            detail: detail,
                            canEditMetadata: dependencies.metadataMutator != nil
                        )
                        EntityDetailToolbarMenu(
                            actions: presentation.modificationActions.filter(isSupported),
                            isEnabled: isEnabled,
                            accessibilityLabel: accessibilityLabel,
                            accessibilityHint: accessibilityHint,
                            onAddToCollection: { collectionSheetPresented = true },
                            onAction: perform
                        )
                    }
                }
            }
            .sheet(isPresented: $collectionSheetPresented) {
                if case .content(let detail) = state.phase {
                    AddToCollectionSheet(
                        items: [
                            CollectionEntityReference(
                                entityType: detail.kind,
                                entityID: detail.id
                            )
                        ]
                    )
                }
            }
        #endif
        #if !os(tvOS)
            .sheet(item: $editPresentation) { presentation in
                editSheet(for: presentation)
            }
        #endif
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

    @ViewBuilder
    private var loadingView: some View {
        #if os(iOS) || os(macOS)
            if link.kind == .audioLibrary, let preview = link.thumbnailPreview {
                MusicAlbumLoadingView(preview: preview)
                    .accessibilityIdentifier("entity-detail.loading")
            } else {
                genericLoadingView
            }
        #else
            genericLoadingView
        #endif
    }

    private var genericLoadingView: some View {
        PrismediaLoadingView("Loading details…")
            .accessibilityIdentifier("entity-detail.loading")
    }

    private func failureView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Details", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Try Again", variant: .prominent) {
                Task { await loadDetail() }
            }
        }
        .accessibilityIdentifier("entity-detail.failure")
    }

    @ViewBuilder
    private func detailView(_ detail: EntityDetail) -> some View {
        switch EntityDestinationPolicy.style(
            for: detail.kind,
            on: .current,
            intent: link.intent
        ) {
        #if os(tvOS)
            case .televisionSeasons:
                TVSeasonsDetailView(
                    rootDetail: detail,
                    routeLink: link,
                    dependencies: dependencies
                )
        #endif
        #if os(iOS) || os(macOS)
            case .nativeAlbum:
                MusicAlbumDetailView(
                    detail: detail,
                    preview: link.thumbnailPreview
                )
            case .nativeArtist:
                MusicArtistDetailView(detail: detail)
            case .nativeAudioCollection:
                if let collectionItemsLoader = dependencies.collectionItemsLoader {
                    MusicCollectionDetailView(
                        detail: detail,
                        preview: link.thumbnailPreview,
                        loader: MusicCollectionQueueLoader(
                            collectionItemsLoader: collectionItemsLoader,
                            detailLoader: dependencies.detailLoader
                        )
                    )
                } else {
                    standardDetailView(detail)
                }
        #endif
        case .nativeImageViewer:
            if let imageViewerSession {
                EntityImageViewerView(
                    session: imageViewerSession,
                    initialDetail: detail,
                    dependencies: dependencies
                )
            } else {
                standardDetailView(detail)
            }
        default:
            standardDetailView(detail)
        }
    }

    @ViewBuilder
    private func standardDetailView(_ detail: EntityDetail) -> some View {
        let presentation = EntityDetailPresentation(
            detail: detail,
            canEditMetadata: dependencies.metadataMutator != nil
        )

        #if os(tvOS)
            if detail.kind == .movie {
                TVEntityDetailBackdropSurface(
                    heroPath: presentation.heroPath,
                    posterPath: presentation.posterPath,
                    previewPath: link.thumbnailPreview?.artworkPath,
                    fallbackSeed: detail.title,
                    systemImage: presentation.systemImage,
                    palette: $artworkPalette
                ) {
                    detailScrollView(
                        detail,
                        presentation: presentation,
                        showsHeroArtwork: false
                    )
                }
            } else {
                standardArtworkDetailView(detail, presentation: presentation)
            }
        #else
            standardArtworkDetailView(detail, presentation: presentation)
        #endif
    }

    private func standardArtworkDetailView(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation
    ) -> some View {
        let activePalette = presentation.heroPath == nil ? nil : artworkPalette

        return detailScrollView(detail, presentation: presentation)
            .environment(\.artworkPalette, activePalette)
            .environment(
                \.artworkPrimaryAccent,
                activePalette?.primary.color ?? PrismediaColor.accent
            )
            .environment(
                \.artworkSecondaryText,
                activePalette?.secondary.color ?? PrismediaColor.textSecondary
            )
    }

    private func detailScrollView(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation,
        showsHeroArtwork: Bool = true
    ) -> some View {
        let playbackOwnerLink = activePlaybackOwnerLink

        return ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        EntityDetailArtworkSurface(
                            artworkPath: EntityDetailHeroArtworkPolicy.atmospherePath(
                                heroPath: presentation.heroPath
                            ),
                            previewPath: presentation.heroPath == nil
                                ? nil
                                : link.thumbnailPreview?.artworkPath,
                            fallbackSeed: detail.title,
                            systemImage: presentation.systemImage,
                            showsAtmosphere: showsHeroArtwork && presentation.heroPath != nil,
                            palette: $artworkPalette
                        ) {
                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                                #if os(tvOS)
                                    if !showsHeroArtwork {
                                        Color.clear
                                            .frame(height: 120)
                                            .accessibilityHidden(true)
                                    }

                                    EntityDetailHeroInformationView(
                                        presentation: presentation,
                                        previewPath: link.thumbnailPreview?.artworkPath,
                                        showsArtwork: showsHeroArtwork,
                                        actions: primaryActions(
                                            for: detail,
                                            fallback: presentation.primaryActions
                                        ),
                                        isMutating: state.isMutating,
                                        canMutate: service.canMutate,
                                        isActionEnabled: isEnabled,
                                        actionHint: accessibilityHint,
                                        onRatingChange: ratingDidChange,
                                        onAction: perform
                                    )
                                #endif

                                if let playbackOwnerLink,
                                    VideoPlaybackLaunchPolicy.presentationMode(
                                        for: playbackOwnerLink
                                    ) == .inline,
                                    PlayableVideoResolver.videoID(
                                        in: detail,
                                        sourceThumbnail: playbackOwnerLink.sourceThumbnail
                                    ) != nil,
                                    let playbackService = dependencies.videoPlaybackService
                                {
                                    VideoEntityPlaybackView(
                                        detail: detail,
                                        ownerLink: playbackOwnerLink,
                                        detailLoader: dependencies.detailLoader,
                                        playbackService: playbackService,
                                        preparation: videoPlaybackPreparation,
                                        presentationMode: VideoPlaybackLaunchPolicy.presentationMode(
                                            for: playbackOwnerLink
                                        ),
                                        presentsFullscreenOnTV:
                                            VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(
                                                for: playbackOwnerLink.intent
                                            ),
                                        onFullscreenDismiss: {
                                            guard
                                                VideoPlaybackLaunchPolicy.presentationMode(
                                                    for: playbackOwnerLink
                                                ) == .fullscreenOnly
                                            else { return }
                                            suppressesRoutePlayback = true
                                            thumbnailPlaybackLink = nil
                                        },
                                        onAdvance: { destination in
                                            guard playbackOwnerLink.kind != .videoSeason else { return }
                                            advancedEntityLink = destination
                                        }
                                    )
                                    .id(playbackOwnerLink)
                                }

                                #if !os(tvOS)
                                    EntityDetailHeroInformationView(
                                        presentation: presentation,
                                        previewPath: link.thumbnailPreview?.artworkPath,
                                        showsArtwork: true,
                                        actions: primaryActions(
                                            for: detail,
                                            fallback: presentation.primaryActions
                                        ),
                                        isMutating: state.isMutating,
                                        canMutate: service.canMutate,
                                        isActionEnabled: isEnabled,
                                        actionHint: accessibilityHint,
                                        onRatingChange: ratingDidChange,
                                        onAction: perform
                                    )
                                #endif
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                            #if os(iOS) || os(macOS)
                                EntityDetailBookProgressView(
                                    combinedProgress: combinedProgressPresentation(for: detail),
                                    readingState: readingState,
                                    audiobookPresentation: audiobookPresentation(for: detail),
                                    listeningErrorMessage: audiobookErrorMessage,
                                    chapters: mappedBookChapters,
                                    chaptersAreLoading: areBookChaptersLoading,
                                    chaptersErrorMessage: bookChaptersErrorMessage,
                                    readingChapterProgressLabel: readingChapterProgressLabel,
                                    listeningChapterProgressLabel: listeningChapterProgressLabel(for: detail),
                                    horizontalPadding: detailHorizontalPadding,
                                    onContinueReading: {
                                        if readingState.requiresResetBeforeReading {
                                            Task { await startReadingOver(openReaderWhenReady: true) }
                                        } else {
                                            openReader(command: .resume)
                                        }
                                    },
                                    onResumeReading: { openReader(command: .resume) },
                                    onContinueListening: { beginListening(to: detail) },
                                    onContinueCombined: { openCombinedReader(for: detail) },
                                    onStartReadingOver: { Task { await startReadingOver() } },
                                    onStartListeningOver: { Task { await startListeningOver(detail) } },
                                    onToggleReadingCompletion: {
                                        let status = readingState.progressPresentation?.status ?? .notStarted
                                        Task { await toggleReadingCompletion(status) }
                                    },
                                    onToggleListeningCompletion: {
                                        Task { await toggleListeningCompletion(detail) }
                                    },
                                    onDismissReadingError: { readingState.dismissError() },
                                    onDismissListeningError: { audiobookErrorMessage = nil },
                                    onRetryReading: { Task { await loadReadingState(for: detail) } },
                                    onReadChapter: { openBookChapter($0, combined: false) },
                                    onListenToChapter: playBookChapter,
                                    onCombineChapter: { openBookChapter($0, combined: true) },
                                    onRetryChapters: { Task { await loadBookChapters(for: detail) } }
                                )
                                .equatable()
                            #endif

                            #if os(tvOS)
                                EntityDetailReadingSection(
                                    state: readingState,
                                    horizontalPadding: detailHorizontalPadding,
                                    onResume: { openReader(command: .resume) },
                                    onStartOver: { Task { await startReadingOver() } },
                                    onToggleCompletion: { status in
                                        Task { await toggleReadingCompletion(status) }
                                    },
                                    onRetry: { Task { await loadReadingState(for: detail) } },
                                    onDismissError: { readingState.dismissError() }
                                )
                            #endif

                            #if os(tvOS)
                                ratingControl(presentation)
                            #endif

                            #if os(tvOS) || os(macOS)
                                modificationActionRow(presentation.modificationActions)
                            #endif

                            EntityDetailSectionContentView(
                                presentation: presentation,
                                selection: $selectedSection,
                                horizontalPadding: detailHorizontalPadding,
                                ownerLink: link,
                                acquisitionService: dependencies.acquisitionService,
                                transcriptSourceLoader: dependencies.transcriptSourceLoader,
                                onAcquisitionMutated: refreshAfterAcquisitionMutation,
                                onEntityPruned: handlePrunedEntity
                            )

                            if selectedSection == .details {
                                mainSupplementView(for: detail)
                            }

                            Color.clear
                                .frame(height: 1)
                                .id("entity-detail.bottom")
                                .accessibilityHidden(true)
                        }
                        .padding(.top, PrismediaSpacing.section)
                        .padding(.bottom, PrismediaSpacing.section)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .refreshable {
                    await loadDetail()
                    if case .content(let refreshedDetail) = state.phase {
                        await loadReadingState(for: refreshedDetail)
                        await loadCollectionMembers(for: refreshedDetail, force: true)
                        await loadAudiobook(for: refreshedDetail)
                        await loadBookChapters(for: refreshedDetail)
                    }
                }
                .task(id: detail.id) {
                    await loadReadingState(for: detail)
                    await loadCollectionMembers(for: detail)
                    await loadAudiobook(for: detail)
                    await loadBookChapters(for: detail)
                }
                #if DEBUG
                    .task(id: detail.id) {
                        guard PrismediaUITestBootstrap.startsEntityDetailAtBottom() else {
                            return
                        }
                        try? await Task.sleep(for: .seconds(1))
                        proxy.scrollTo("entity-detail.bottom", anchor: .bottom)
                    }
                #endif
                .accessibilityIdentifier("entity-detail.content")
            }

            if let playbackOwnerLink,
                VideoPlaybackLaunchPolicy.presentationMode(
                    for: playbackOwnerLink
                ) == .fullscreenOnly,
                PlayableVideoResolver.videoID(
                    in: detail,
                    sourceThumbnail: playbackOwnerLink.sourceThumbnail
                ) != nil,
                let playbackService = dependencies.videoPlaybackService
            {
                VideoEntityPlaybackView(
                    detail: detail,
                    ownerLink: playbackOwnerLink,
                    detailLoader: dependencies.detailLoader,
                    playbackService: playbackService,
                    preparation: videoPlaybackPreparation,
                    presentationMode: .fullscreenOnly,
                    presentsFullscreenOnTV: VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(
                        for: playbackOwnerLink.intent
                    ),
                    onFullscreenDismiss: {
                        suppressesRoutePlayback = true
                        thumbnailPlaybackLink = nil
                    },
                    onAdvance: { _ in }
                )
                .id(playbackOwnerLink)
            }
        }
    }

    private var activePlaybackOwnerLink: EntityLink? {
        if let thumbnailPlaybackLink { return thumbnailPlaybackLink }
        if suppressesRoutePlayback { return nil }
        return link
    }

    private func ratingDidChange(_ value: Int?) {
        Task {
            if await updateRating(value) {
                dependencies.onEntityMutated()
            }
        }
    }

    private func visibleChildGroups(in detail: EntityDetail) -> [EntityGroup] {
        switch detail.kind {
        case .book where detail.bookFormat == .epub && AudiobookPlaybackProjection(detail: detail) != nil:
            return detail.childrenByKind.filter { $0.kind != .audioTrack }
        case .movie:
            return detail.childrenByKind.filter { $0.kind != .video }
        default:
            return detail.childrenByKind
        }
    }

    @ViewBuilder
    private func childGroupsView(for detail: EntityDetail) -> some View {
        if GalleryChildGroupsPresentation.isAvailable(for: detail.kind) {
            GalleryDetailChildGroupsView(
                galleryID: detail.id,
                groups: detail.childrenByKind,
                horizontalPadding: detailHorizontalPadding,
                dependencies: dependencies
            )
        } else {
            if detail.kind == .videoSeason {
                EntityDetailChildGroupsView(
                    groups: visibleChildGroups(in: detail),
                    horizontalPadding: detailHorizontalPadding,
                    onPrimaryAction: beginThumbnailPlayback
                )
            } else {
                EntityDetailChildGroupsView(
                    groups: visibleChildGroups(in: detail),
                    horizontalPadding: detailHorizontalPadding
                )
            }
        }
    }

    @ViewBuilder
    private func mainSupplementView(for detail: EntityDetail) -> some View {
        if let referencePresentation = EntityDetailReferencedContentPresentation(detail: detail),
            let entityGridLoader = dependencies.entityGridLoader
        {
            EntityDetailReferencedContentView(
                presentation: referencePresentation,
                loader: entityGridLoader
            )
            .padding(.horizontal, detailHorizontalPadding)
        }

        if detail.kind == .collection {
            CollectionMembersView(
                phase: collectionMembersState.phase,
                horizontalPadding: detailHorizontalPadding,
                retry: {
                    Task { await reloadCollectionMembers() }
                }
            )
        } else if !visibleChildGroups(in: detail).isEmpty {
            childGroupsView(for: detail)
        }
    }

    private func beginThumbnailPlayback(_ thumbnail: EntityThumbnail) {
        suppressesRoutePlayback = false
        thumbnailPlaybackLink = EntityLink(thumbnail: thumbnail, intent: .playback)
    }

    private func reloadCollectionMembers() async {
        guard case .content(let detail) = state.phase else { return }
        await loadCollectionMembers(for: detail, force: true)
    }

    private func loadCollectionMembers(for detail: EntityDetail, force: Bool = false) async {
        guard detail.kind == .collection else {
            collectionMembersState.reset()
            return
        }
        guard
            let request = collectionMembersState.beginLoad(
                collectionID: detail.id,
                force: force
            )
        else { return }

        let outcome = await collectionMembersService.load(collectionID: detail.id)
        collectionMembersState.finishLoad(outcome, request: request)
    }

    private func loadDetail() async {
        guard let request = state.beginLoad() else { return }
        let outcome = await service.load(id: link.entityID, kind: link.kind)
        state.finishLoad(outcome, request: request)
    }

    private func refreshAfterAcquisitionMutation() async {
        dependencies.onEntityMutated()
        await loadDetail()
    }

    private func handlePrunedEntity() {
        dependencies.onEntityMutated()
        dismiss()
    }

    private func updateRating(_ value: Int?) async -> Bool {
        await performMutation(.rating(value))
    }

    private func toggleFlag(_ action: EntityDetailActionID) async -> Bool {
        let mutation: EntityDetailMutation?
        switch action {
        case .favorite:
            mutation = state.favoriteToggleMutation
        case .organized:
            mutation = state.organizedToggleMutation
        default:
            mutation = nil
        }
        guard let mutation else { return false }
        return await performMutation(mutation)
    }

    private func performMutation(_ mutation: EntityDetailMutation) async -> Bool {
        guard let request = state.beginMutation(canMutate: service.canMutate) else {
            return false
        }

        let saveOutcome = await service.save(mutation, id: link.entityID)
        guard state.finishMutationSave(saveOutcome, request: request) else {
            return false
        }

        let refreshOutcome = await service.load(id: link.entityID, kind: link.kind)
        state.finishMutationRefresh(refreshOutcome, request: request)
        return true
    }

    private var detailHorizontalPadding: CGFloat {
        #if os(tvOS)
            72
        #else
            20
        #endif
    }

    @ViewBuilder
    private func ratingControl(_ presentation: EntityDetailPresentation) -> some View {
        if presentation.hasRatingCapability {
            EntityDetailStarRatingControl(
                value: presentation.rating,
                isDisabled: state.isMutating || !service.canMutate
            ) { ratingDidChange($0) }
            .padding(.horizontal, detailHorizontalPadding)
            .prismediaFocusSection()
        }
    }

    @ViewBuilder
    private func modificationActionRow(_ actions: [EntityDetailAction]) -> some View {
        let supportedActions = actions.filter(isSupported)
        if !supportedActions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                #if os(tvOS)
                    HStack(spacing: PrismediaSpacing.section) {
                        ForEach(supportedActions) { action in
                            Button {
                                perform(action)
                            } label: {
                                Image(systemName: action.isSelected ? selectedImage(for: action) : action.systemImage)
                                    .font(.title3.weight(.semibold))
                                    .frame(width: 64, height: 58)
                            }
                            .buttonStyle(.glass)
                            .foregroundStyle(
                                action.isSelected
                                    ? artworkPalette?.primary.color ?? PrismediaColor.accent
                                    : PrismediaColor.onMedia
                            )
                            .disabled(!isEnabled(action))
                            .accessibilityLabel(accessibilityLabel(for: action))
                            .accessibilityHint(accessibilityHint(for: action))
                            .accessibilityAddTraits(action.isSelected ? .isSelected : [])
                            .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
                        }
                    }
                    .padding(.horizontal, detailHorizontalPadding)
                    .padding(.vertical, PrismediaSpacing.large)
                #else
                    HStack(spacing: PrismediaSpacing.medium) {
                        ForEach(supportedActions) { action in
                            Button {
                                perform(action)
                            } label: {
                                Image(systemName: action.isSelected ? selectedImage(for: action) : action.systemImage)
                                    .frame(width: 42)
                                    .accessibilityHidden(true)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(actionTint(action))
                            .frame(height: 42)
                            .background(
                                PrismediaColor.controlFill.opacity(0.92),
                                in: Circle()
                            )
                            .overlay {
                                Circle().stroke(actionTint(action).opacity(0.32), lineWidth: PrismediaLayout.hairline)
                            }
                            .buttonStyle(.plain)
                            .disabled(!isEnabled(action))
                            .opacity(1)
                            .accessibilityLabel(accessibilityLabel(for: action))
                            .accessibilityHint(accessibilityHint(for: action))
                            .accessibilityAddTraits(action.isSelected ? .isSelected : [])
                            .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
                        }
                    }
                    .padding(.horizontal, detailHorizontalPadding)
                #endif
            }
            .prismediaFocusSection()
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Entity actions")
            .accessibilityIdentifier("entity-detail.modification-actions")
        }
    }

    private func selectedImage(for action: EntityDetailAction) -> String {
        switch action.id {
        case .favorite: return "heart.fill"
        case .organized: return "checkmark.circle.fill"
        default: return action.systemImage
        }
    }

    private func actionTint(_ action: EntityDetailAction) -> Color {
        action.isSelected
            ? artworkPalette?.primary.color ?? PrismediaColor.accent
            : artworkPalette?.secondary.color ?? PrismediaColor.textSecondary
    }

    private func isEnabled(_ action: EntityDetailAction) -> Bool {
        if action.id == .edit {
            return !state.isMutating
                && dependencies.metadataMutator != nil
                && dependencies.entityGridLoader != nil
        }
        if action.id == .listen {
            #if os(iOS) || os(macOS)
                return audiobookProjection != nil
                    && !isAudiobookLoading
                    && !isListeningMutating
                    && dependencies.audioPlaybackService != nil
            #else
                return false
            #endif
        }
        if action.id == .read || action.id == .resume {
            #if os(tvOS)
                return false
            #else
                return readingService.isAvailable && currentBookUsesNativeReader
            #endif
        }
        guard !state.isMutating, service.canMutate else { return false }
        return isSupported(action)
    }

    private func isSupported(_ action: EntityDetailAction) -> Bool {
        if action.id == .edit {
            #if os(tvOS)
                return false
            #else
                return dependencies.metadataMutator != nil
            #endif
        }
        if action.id == .listen {
            #if os(iOS) || os(macOS)
                return audiobookProjection != nil
            #else
                return false
            #endif
        }
        if action.id == .read || action.id == .resume {
            #if os(tvOS)
                return false
            #else
                return readingService.isAvailable
            #endif
        }
        return action.id == .favorite || action.id == .organized
    }

    private func perform(_ action: EntityDetailAction) {
        switch action.id {
        case .favorite:
            Task {
                if await toggleFlag(.favorite) {
                    dependencies.onEntityMutated()
                }
            }
        case .organized:
            Task {
                if await toggleFlag(.organized) {
                    dependencies.onEntityMutated()
                }
            }
        case .read:
            if readingState.requiresResetBeforeReading {
                Task { await startReadingOver(openReaderWhenReady: true) }
            } else {
                openReader(command: .read)
            }
        case .resume:
            openReader(command: .resume)
        case .listen:
            #if os(iOS) || os(macOS)
                guard case .content(let detail) = state.phase else { return }
                let presentation = audiobookPresentation(for: detail)
                if presentation?.actionTitle == "Pause" {
                    musicPlayer.pause()
                } else {
                    beginListening(to: detail)
                }
            #endif
        case .edit:
            guard case .content(let detail) = state.phase,
                dependencies.metadataMutator != nil,
                dependencies.entityGridLoader != nil
            else { return }
            editPresentation = EntityDetailEditPresentation(detail: detail)
        default:
            break
        }
    }

    private func accessibilityLabel(for action: EntityDetailAction) -> String {
        switch action.id {
        case .favorite:
            return action.isSelected ? "Remove from favorites" : "Add to favorites"
        case .organized:
            return action.isSelected ? "Mark as unorganized" : "Mark as organized"
        default:
            return action.title
        }
    }

    private func accessibilityHint(for action: EntityDetailAction) -> String {
        if action.id == .listen {
            return isEnabled(action)
                ? "Plays this audiobook in the native audio player"
                : "This audiobook is still preparing"
        }
        if action.id == .read || action.id == .resume {
            return isEnabled(action) ? "Opens the native reader" : "This item cannot be opened in the native reader"
        }
        if action.id == .edit {
            return isEnabled(action)
                ? "Opens the Main and Metadata editor"
                : "Editing requires taxonomy search to be available"
        }
        return isEnabled(action) ? "Updates this entity" : "This action is not available in the native app yet"
    }

    @ViewBuilder
    private func editSheet(
        for presentation: EntityDetailEditPresentation
    ) -> some View {
        if let metadataMutator = dependencies.metadataMutator,
            let entityGridLoader = dependencies.entityGridLoader
        {
            EntityDetailEditSheet(
                presentation: presentation,
                service: EntityDetailEditService(
                    metadataMutator: metadataMutator,
                    userMetadataMutator: dependencies.mutator
                ),
                referenceLoader: entityGridLoader,
                onSaved: {
                    await loadDetail()
                    dependencies.onEntityMutated()
                }
            )
        }
    }

    private var currentBookUsesNativeReader: Bool {
        guard case .content(let detail) = state.phase else { return false }
        switch BookReaderFormatPolicy.route(
            for: detail.kind,
            format: detail.bookFormat
        ) {
        case .comic, .pdf, .epub:
            return true
        case .unavailable, .unsupported:
            return false
        }
    }

    private func openReader(command: BookReaderCommand) {
        guard case .content(let detail) = state.phase,
            dependencies.readerService != nil
        else { return }
        readerPresentation = .init(detail: detail, command: command)
    }

    private func loadReadingState(for detail: EntityDetail) async {
        guard readingService.isAvailable,
            [.book, .bookVolume, .bookChapter].contains(detail.kind),
            detail.bookFormat != .audio
        else {
            readingState.reset()
            return
        }

        let request = readingState.beginLoad(entityID: detail.id)
        let outcome = await readingService.load(detail: detail)
        readingState.finishLoad(outcome, request: request)
    }

    private func reloadReadingState() async {
        guard case .content(let detail) = state.phase,
            readingService.isAvailable,
            [.book, .bookVolume, .bookChapter].contains(detail.kind),
            detail.bookFormat != .audio
        else {
            readingState.reset()
            return
        }

        let request = readingState.beginLoad(entityID: detail.id)
        let outcome = await readingService.reload(detailID: detail.id, kind: detail.kind)
        readingState.finishLoad(outcome, request: request)
    }

    private func startReadingOver(openReaderWhenReady: Bool = false) async {
        guard case .content(let detail) = state.phase,
            let manifest = readingState.manifest,
            let request = readingState.beginMutation()
        else { return }

        let outcome = await readingService.startOver(
            detail: detail,
            readerMode: manifest.readerMode
        )
        guard readingState.finishMutation(outcome, request: request) else { return }

        dependencies.onEntityMutated()
        guard openReaderWhenReady else { return }

        if case .singleFile(let refreshedDetail) = outcome {
            presentReader(detail: refreshedDetail, command: .resume)
        } else {
            openReader(command: .resume)
        }
    }

    private func presentReader(detail: EntityDetail, command: BookReaderCommand) {
        guard dependencies.readerService != nil else { return }
        readerPresentation = .init(detail: detail, command: command)
    }

    private func presentReader(
        detail: EntityDetail,
        location: String,
        progression: Double? = nil,
        companionAudiobookBookID: UUID?,
        companionAudiobookTrackID: UUID?,
        companionAudiobookStartSeconds: Double = 0
    ) {
        guard dependencies.readerService != nil else { return }
        readerPresentation = .init(
            detail: detail,
            command: .read,
            initialEPUBLocation: location,
            initialEPUBProgression: progression,
            companionAudiobookBookID: companionAudiobookBookID,
            companionAudiobookTrackID: companionAudiobookTrackID,
            companionAudiobookStartSeconds: companionAudiobookStartSeconds
        )
    }

    private func toggleReadingCompletion(_ status: MediaProgressStatus) async {
        guard case .content(let detail) = state.phase,
            let manifest = readingState.manifest,
            let request = readingState.beginMutation()
        else { return }

        let outcome = await readingService.toggleCompletion(
            detail: detail,
            manifest: manifest,
            status: status
        )
        if readingState.finishMutation(outcome, request: request) {
            dependencies.onEntityMutated()
        }
    }

    private func primaryActions(
        for detail: EntityDetail,
        fallback: [EntityDetailAction]
    ) -> [EntityDetailAction] {
        var actions = readingState.primaryActions(
            fallback: fallback,
            entityKind: detail.kind
        )
        if readingState.progressPresentation?.canResume == true {
            actions.removeAll { $0.id == .read || $0.id == .resume }
        }
        if detail.bookFormat == .audio {
            actions.removeAll { $0.id == .read || $0.id == .resume }
        }

        #if os(iOS) || os(macOS)
            if let presentation = audiobookPresentation(for: detail),
                presentation.actionTitle != "Continue Listening"
            {
                actions.append(
                    EntityDetailAction(
                        id: .listen,
                        title: presentation.actionTitle,
                        systemImage: "headphones",
                        isSelected: musicPlayer.context?.playbackOwnerEntityID == detail.id,
                        isPrimary: true
                    )
                )
            }
        #endif
        return actions
    }

    private func loadAudiobook(for detail: EntityDetail) async {
        #if os(iOS) || os(macOS)
            guard let baseProjection = AudiobookPlaybackProjection(detail: detail) else {
                audiobookProjection = nil
                refreshBookChapterMappings(for: detail)
                isAudiobookLoading = false
                audiobookErrorMessage = nil
                return
            }

            audiobookProjection = baseProjection
            refreshBookChapterMappings(for: detail)
            isAudiobookLoading = true
            let hydrated = await AudiobookQueueLoader(detailLoader: dependencies.detailLoader).load(detail: detail)
            guard case .content(let currentDetail) = state.phase,
                currentDetail.id == detail.id
            else { return }
            audiobookProjection = hydrated ?? baseProjection
            refreshBookChapterMappings(for: currentDetail)
            isAudiobookLoading = false
        #else
            audiobookProjection = nil
            isAudiobookLoading = false
        #endif
    }

    private func loadBookChapters(for detail: EntityDetail) async {
        #if os(iOS) || os(macOS)
            guard detail.kind == .book,
                detail.bookFormat == .epub,
                let reader = dependencies.readerService
            else {
                readableBookChapters = []
                mappedBookChapters = []
                currentReadableChapterID = nil
                areBookChaptersLoading = false
                bookChaptersErrorMessage = nil
                return
            }

            areBookChaptersLoading = true
            bookChaptersErrorMessage = nil
            defer { areBookChaptersLoading = false }
            do {
                let contents = try await EPUBChapterContentsService(reader: reader).load(
                    book: detail,
                    storedLocation: dependencies.readerLocatorStore.load(bookID: detail.id)
                )
                guard case .content(let currentDetail) = state.phase,
                    currentDetail.id == detail.id
                else { return }
                readableBookChapters = contents.chapters
                if detail.capability(EntityProgressCapability.self)?.completedAt != nil {
                    currentReadableChapterID = nil
                } else if let currentChapterID = contents.currentChapterID {
                    currentReadableChapterID = currentChapterID
                } else if !contents.chapters.contains(where: { $0.id == currentReadableChapterID }) {
                    currentReadableChapterID = nil
                }
                refreshBookChapterMappings(for: currentDetail)
            } catch is CancellationError {
                return
            } catch {
                readableBookChapters = []
                mappedBookChapters = []
                currentReadableChapterID = nil
                bookChaptersErrorMessage = error.localizedDescription
            }
        #else
            readableBookChapters = []
            mappedBookChapters = []
            currentReadableChapterID = nil
            areBookChaptersLoading = false
            bookChaptersErrorMessage = nil
        #endif
    }

    #if os(iOS) || os(macOS)
        private func refreshBookChapterMappings(for detail: EntityDetail) {
            guard detail.kind == .book, detail.bookFormat == .epub else {
                mappedBookChapters = []
                return
            }
            guard !readableBookChapters.isEmpty else {
                mappedBookChapters = []
                return
            }
            mappedBookChapters = BookChapterMappingBuilder().build(
                readableChapters: readableBookChapters,
                audioTracks: audiobookProjection?.tracks ?? [],
                currentReadableID: currentReadableChapterID,
                currentAudioTrackID: currentAudiobookTrackID(for: detail)
            )
        }

        private func currentAudiobookTrackID(for detail: EntityDetail) -> UUID? {
            guard let projection = audiobookProjection else { return nil }
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrent { return musicPlayer.currentTrack?.id }
            let playback = detail.capability(EntityPlaybackCapability.self)
            guard playback?.completedAt == nil else { return nil }
            let savedResume = playback?.resumeSeconds ?? 0
            guard savedResume > 0 else { return nil }
            return projection.resumePoint(at: savedResume)?.trackID
        }

        private var readingChapterProgressLabel: String? {
            guard let progress = readingState.progressPresentation else { return nil }
            if let positionLabel = progress.positionLabel { return positionLabel }
            return progress.status == .completed ? "Complete" : "\(progress.percent)% read"
        }

        private func listeningChapterProgressLabel(for detail: EntityDetail) -> String? {
            guard let progress = audiobookPresentation(for: detail)?.progress else { return nil }
            if let positionLabel = progress.positionLabel { return positionLabel }
            return progress.status == .completed ? "Complete" : "\(progress.percent)% listened"
        }

        private func combinedProgressPresentation(
            for detail: EntityDetail
        ) -> BookCombinedProgressPresentation? {
            guard detail.kind == .book,
                detail.bookFormat == .epub,
                audiobookProjection?.bookID == detail.id,
                let target = combinedResumeTarget(for: detail),
                readingCheckpoint(for: detail) != nil || listeningCheckpoint(for: detail) != nil
            else { return nil }
            return BookCombinedProgressPresentation(
                reading: readingState.progressPresentation,
                listening: audiobookPresentation(for: detail),
                combinedUsesReadingPosition: target.readingTarget == .savedLocation,
                isBusy: readingState.isMutating || isListeningMutating || isAudiobookLoading
            )
        }

        private func combinedResumeTarget(
            for detail: EntityDetail
        ) -> BookCombinedResumeTarget? {
            BookCombinedResumeResolver().resolveContinuation(
                chapters: mappedBookChapters,
                reading: readingCheckpoint(for: detail),
                listening: listeningCheckpoint(for: detail)
            )
        }

        private func currentAudiobookReadingTarget(
            for detail: EntityDetail
        ) -> BookReaderLocationTarget? {
            guard let listening = listeningCheckpoint(for: detail) else { return nil }
            return BookCombinedResumeResolver().resolveReadingTarget(
                chapters: mappedBookChapters,
                listening: listening
            )
        }

        private func readingCheckpoint(for detail: EntityDetail) -> BookReadingCheckpoint? {
            let progress: EntityProgressCapability? =
                readingState.manifest?.progress
                ?? detail.capability()
            guard progress?.completedAt == nil else { return nil }
            let serialized =
                dependencies.readerLocatorStore.load(bookID: detail.id)
                ?? progress?.location
            guard let serialized,
                let location = EPUBProgressLocation(serialized: serialized)
            else { return nil }
            let publicationProgression =
                location.totalProgression
                ?? {
                    guard let progress else { return 0 }
                    return Double(max(0, progress.index)) / Double(max(1, progress.total))
                }()
            return BookReadingCheckpoint(
                chapterLocation: location.href,
                chapterProgression: location.resourceProgression,
                publicationProgression: publicationProgression
            )
        }

        private func listeningCheckpoint(for detail: EntityDetail) -> BookListeningCheckpoint? {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id,
                detail.capability(EntityPlaybackCapability.self)?.completedAt == nil
            else { return nil }
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            let resume: AudiobookResumePoint?
            if isCurrent, let track = musicPlayer.currentTrack {
                resume = AudiobookResumePoint(
                    trackID: track.id,
                    trackOffsetSeconds: musicPlayer.elapsedTime
                )
            } else {
                let saved = detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
                guard saved > 0 else { return nil }
                resume = projection.resumePoint(at: saved)
            }
            guard let resume else { return nil }
            let absolute = projection.absoluteTime(
                trackID: resume.trackID,
                trackOffsetSeconds: resume.trackOffsetSeconds
            )
            return BookListeningCheckpoint(
                trackID: resume.trackID,
                trackOffsetSeconds: resume.trackOffsetSeconds,
                publicationProgression: projection.totalDuration > 0
                    ? absolute / projection.totalDuration
                    : 0
            )
        }

        private func openBookChapter(_ chapter: BookChapterMapping, combined: Bool) {
            guard case .content(let detail) = state.phase,
                case .some(.epub(let location)) = chapter.readTarget
            else { return }

            currentReadableChapterID =
                readableBookChapters.first {
                    guard case .epub(let candidateLocation) = $0.target else { return false }
                    return candidateLocation == location
                }?.id
            refreshBookChapterMappings(for: detail)

            if combined {
                guard
                    let target = BookCombinedResumeResolver().resolveChapter(
                        chapter,
                        reading: readingCheckpoint(for: detail),
                        listening: listeningCheckpoint(for: detail)
                    )
                else { return }
                let isCurrentBook =
                    musicPlayer.context?.playbackOwnerEntityID == detail.id
                    && musicPlayer.context?.playbackOwnerEntityKind == .book
                if isCurrentBook, musicPlayer.isPlaying { musicPlayer.pause() }
                presentCombinedReader(detail: detail, target: target)
                return
            }

            presentReader(
                detail: detail,
                location: location,
                companionAudiobookBookID: nil,
                companionAudiobookTrackID: nil
            )
        }

        private func openCombinedReader(for detail: EntityDetail) {
            guard let target = combinedResumeTarget(for: detail) else { return }
            let isCurrentBook =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrentBook, musicPlayer.isPlaying { musicPlayer.pause() }
            presentCombinedReader(detail: detail, target: target)
        }

        private func presentCombinedReader(
            detail: EntityDetail,
            target: BookCombinedResumeTarget
        ) {
            switch target.readingTarget {
            case .savedLocation:
                readerPresentation = .init(
                    detail: detail,
                    command: .resume,
                    companionAudiobookBookID: detail.id,
                    companionAudiobookTrackID: target.audioTrackID,
                    companionAudiobookStartSeconds: target.audioStartSeconds
                )
            case .chapter(let location, let progression):
                presentReader(
                    detail: detail,
                    location: location,
                    progression: progression,
                    companionAudiobookBookID: detail.id,
                    companionAudiobookTrackID: target.audioTrackID,
                    companionAudiobookStartSeconds: target.audioStartSeconds
                )
            }
        }

        private func beginCombinedPlayback(for presentation: EntityReaderPresentation) {
            pendingCombinedPlaybackTask?.cancel()
            pendingCombinedPlaybackTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                guard !Task.isCancelled,
                    readerPresentation == presentation,
                    let bookID = presentation.companionAudiobookBookID,
                    let trackID = presentation.companionAudiobookTrackID,
                    let projection = audiobookProjection,
                    projection.bookID == bookID,
                    projection.tracks.contains(where: { $0.id == trackID })
                else { return }

                play(
                    projection,
                    startingAt: trackID,
                    startSeconds: presentation.companionAudiobookStartSeconds
                )
                refreshBookChapterMappings(for: presentation.detail)
                pendingCombinedPlaybackTask = nil
            }
        }

        private func playBookChapter(_ chapter: BookChapterMapping) {
            guard case .content(let detail) = state.phase,
                let projection = audiobookProjection,
                projection.bookID == detail.id,
                let track = chapter.audioTrack
            else { return }
            play(projection, startingAt: track.id, startSeconds: 0)
        }

        private func audiobookPresentation(for detail: EntityDetail) -> AudiobookPlaybackPresentation? {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id
            else { return nil }
            let playback = detail.capability(EntityPlaybackCapability.self)
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            let currentResume: Double
            if isCurrent, let currentTrack = musicPlayer.currentTrack {
                currentResume = projection.absoluteTime(
                    trackID: currentTrack.id,
                    trackOffsetSeconds: musicPlayer.elapsedTime
                )
            } else {
                currentResume = playback?.resumeSeconds ?? 0
            }
            return AudiobookPlaybackPresentation(
                totalDuration: projection.totalDuration,
                partCount: projection.tracks.count,
                resumeSeconds: currentResume,
                isCompleted: playback?.completedAt != nil,
                isCurrentAudiobook: isCurrent,
                isPlaying: musicPlayer.isPlaying,
                isBusy: isListeningMutating || isAudiobookLoading
            )
        }

        private func beginListening(to detail: EntityDetail) {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id
            else { return }
            let completed = detail.capability(EntityPlaybackCapability.self)?.completedAt != nil
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrent && !completed {
                musicPlayer.resume()
                return
            }
            if completed {
                Task { await startListeningOver(detail) }
                return
            }
            let savedResume = detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
            play(projection, resumeSeconds: savedResume)
        }

        private func play(_ projection: AudiobookPlaybackProjection, resumeSeconds: Double) {
            guard let resume = projection.resumePoint(at: resumeSeconds) else { return }
            play(
                projection,
                startingAt: resume.trackID,
                startSeconds: resume.trackOffsetSeconds
            )
        }

        private func play(
            _ projection: AudiobookPlaybackProjection,
            startingAt trackID: UUID,
            startSeconds: Double
        ) {
            musicPlayer.play(
                tracks: projection.tracks,
                startingAt: trackID,
                queueMode: .ordered,
                context: MusicPlaybackContext(
                    playbackOwnerEntityID: projection.bookID,
                    playbackOwnerTitle: projection.title,
                    playbackOwnerEntityKind: .book
                ),
                startSeconds: startSeconds
            )
        }

        private func startListeningOver(_ detail: EntityDetail) async {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id,
                let playbackService = dependencies.audioPlaybackService,
                !isListeningMutating
            else { return }
            isListeningMutating = true
            audiobookErrorMessage = nil
            do {
                await musicPlayer.flushPendingPlaybackReports()
                musicPlayer.setAudiobookCompletionState(false)
                try await playbackService.updateEntityPlayback(
                    id: detail.id,
                    resumeSeconds: 0,
                    completed: false
                )
                play(projection, resumeSeconds: 0)
                await refreshAudiobookDetail()
            } catch {
                audiobookErrorMessage = error.localizedDescription
            }
            isListeningMutating = false
        }

        private func toggleListeningCompletion(_ detail: EntityDetail) async {
            guard let presentation = audiobookPresentation(for: detail),
                let playbackService = dependencies.audioPlaybackService,
                !isListeningMutating
            else { return }
            isListeningMutating = true
            audiobookErrorMessage = nil
            let marksCompleted = presentation.progress.status != .completed
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            do {
                await musicPlayer.flushPendingPlaybackReports()
                if isCurrent { musicPlayer.setAudiobookCompletionState(marksCompleted) }
                try await playbackService.updateEntityPlayback(
                    id: detail.id,
                    resumeSeconds: presentation.progress.status == .completed
                        ? 0
                        : currentAudiobookResume(for: detail),
                    completed: marksCompleted
                )
                await refreshAudiobookDetail()
            } catch {
                if isCurrent { musicPlayer.setAudiobookCompletionState(!marksCompleted) }
                audiobookErrorMessage = error.localizedDescription
            }
            isListeningMutating = false
        }

        private func currentAudiobookResume(for detail: EntityDetail) -> Double {
            guard let projection = audiobookProjection else { return 0 }
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrent, let track = musicPlayer.currentTrack {
                return projection.absoluteTime(
                    trackID: track.id,
                    trackOffsetSeconds: musicPlayer.elapsedTime
                )
            }
            return detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
        }

        private func refreshAudiobookDetail() async {
            await loadDetail()
            if case .content(let refreshed) = state.phase {
                await loadAudiobook(for: refreshed)
            }
            dependencies.onEntityMutated()
        }
    #endif

    private func companionPlayer(
        for presentation: EntityReaderPresentation
    ) -> MusicPlayerController? {
        #if os(iOS) || os(macOS)
            guard presentation.companionAudiobookBookID != nil else { return nil }
            return musicPlayer
        #else
            return nil
        #endif
    }

    private func pauseCompanionAudiobook(
        for presentation: EntityReaderPresentation?
    ) {
        #if os(iOS) || os(macOS)
            guard let bookID = presentation?.companionAudiobookBookID,
                musicPlayer.context?.playbackOwnerEntityID == bookID,
                musicPlayer.context?.playbackOwnerEntityKind == .book,
                musicPlayer.isPlaying
            else { return }
            musicPlayer.pause()
        #endif
    }

    private var navigationTitle: String {
        guard case .content(let detail) = state.phase else {
            return link.thumbnailPreview?.title ?? ""
        }
        return detail.title
    }

    private var mutationErrorPresented: Binding<Bool> {
        Binding(
            get: { state.mutationErrorMessage != nil },
            set: { isPresented in
                if !isPresented { state.dismissMutationError() }
            }
        )
    }
}

extension View {
    @ViewBuilder
    fileprivate func prismediaReaderCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
            fullScreenCover(item: item, content: content)
        #else
            sheet(item: item, content: content)
        #endif
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
