import SwiftUI

extension EntityDetailView {
    func detailScrollView(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation,
        showsHeroArtwork: Bool = true,
        showsPageAtmosphere: Bool = true
    ) -> some View {
        let playbackOwnerLink = activePlaybackOwnerLink
        let paletteArtworkPath =
            presentation.posterPath
            ?? link.thumbnailPreview?.artworkPath

        return ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        EntityDetailArtworkSurface(
                            artworkPath: paletteArtworkPath,
                            paletteArtworkPath: paletteArtworkPath,
                            previewPath: link.thumbnailPreview?.artworkPath,
                            fallbackSeed: detail.title,
                            systemImage: presentation.systemImage,
                            showsAtmosphere: false,
                            showsArtworkInBackdrop: false,
                            palette: $artworkPalette
                        ) {
                            EntityDetailPlatformHeroStack(
                                showsHeroArtwork: showsHeroArtwork,
                                hero: {
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
                                },
                                playback: {
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
                                            trickplayFrameLoader: dependencies.trickplayFrameLoader,
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
                                            onPlaybackProgressCommitted: {
                                                Task { await refreshPlaybackState() }
                                            },
                                            onAdvance: { destination in
                                                guard playbackOwnerLink.kind != .videoSeason else { return }
                                                advancedEntityLink = destination
                                            }
                                        )
                                        .id(playbackOwnerLink)
                                    }
                                }
                            )
                        }

                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                            EntityDetailVideoProgressView(
                                presentation: videoProgressCardPresentation(for: detail),
                                errorMessage: videoProgressErrorMessage,
                                horizontalPadding: detailHorizontalPadding,
                                onContinue: continueVideoProgress,
                                onStartOver: {
                                    Task { await startVideoProgressOver() }
                                },
                                onToggleCompletion: {
                                    Task { await toggleVideoProgressCompletion() }
                                },
                                onDismissError: { videoProgressErrorMessage = nil }
                            )

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

                            EntityDetailPlatformActionsView(
                                presentation: presentation,
                                isMutating: state.isMutating,
                                canMutate: service.canMutate,
                                palette: artworkPalette,
                                horizontalPadding: detailHorizontalPadding,
                                isActionSupported: isSupported,
                                isActionEnabled: isEnabled,
                                actionHint: accessibilityHint,
                                onRatingChange: ratingDidChange,
                                onAction: perform
                            )

                            EntityDetailSectionContentView(
                                presentation: presentation,
                                selection: $selectedSection,
                                horizontalPadding: detailHorizontalPadding,
                                ownerLink: link,
                                acquisitionService: dependencies.acquisitionService,
                                requestActivityService: dependencies.requestActivityService,
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
                        await loadVideoProgress(for: refreshedDetail)
                        await loadReadingState(for: refreshedDetail)
                        await loadCollectionMembers(for: refreshedDetail, force: true)
                        await loadAudiobook(for: refreshedDetail)
                        await loadBookChapters(for: refreshedDetail)
                    }
                }
                .task(id: detail.id) {
                    await loadVideoProgress(for: detail)
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
                    trickplayFrameLoader: dependencies.trickplayFrameLoader,
                    preparation: videoPlaybackPreparation,
                    presentationMode: .fullscreenOnly,
                    presentsFullscreenOnTV: VideoPlaybackLaunchPolicy.shouldPrepareAutomatically(
                        for: playbackOwnerLink.intent
                    ),
                    onFullscreenDismiss: {
                        suppressesRoutePlayback = true
                        thumbnailPlaybackLink = nil
                    },
                    onPlaybackProgressCommitted: {
                        Task { await refreshPlaybackState() }
                    },
                    onAdvance: { _ in }
                )
                .id(playbackOwnerLink)
            }
        }
        .background {
            if showsPageAtmosphere {
                ArtworkPaletteSurface(
                    artworkPath: paletteArtworkPath,
                    paletteArtworkPath: paletteArtworkPath,
                    previewPath: link.thumbnailPreview?.artworkPath,
                    fallbackSeed: detail.title,
                    systemImage: presentation.systemImage,
                    showsArtworkInBackdrop: false,
                    palette: $artworkPalette
                ) {
                    Color.clear
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}
