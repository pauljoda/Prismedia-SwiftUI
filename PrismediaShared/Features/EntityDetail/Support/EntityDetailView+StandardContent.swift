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
                                    EntityDetailPlatformOverviewView(
                                        presentation: presentation,
                                        previewPath: link.thumbnailPreview?.artworkPath,
                                        showsArtwork: showsHeroArtwork
                                    ) {
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
                                    }
                                },
                                playback: {
                                    inlineVideoPlaybackView(
                                        detail,
                                        ownerLink: playbackOwnerLink
                                    )
                                }
                            )
                        }

                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                            EntityDetailPlatformContentLayout(
                                selectedSection: selectedSection,
                                browseContent: {
                                    mainSupplementView(for: detail)
                                },
                                secondaryContent: {
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
                                                listeningChapterProgressLabel: listeningChapterProgressLabel(
                                                    for: detail),
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
                                                    let status =
                                                        readingState.progressPresentation?.status ?? .notStarted
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

                                        EntityDetailSectionContentView(
                                            presentation: presentation,
                                            selection: $selectedSection,
                                            horizontalPadding: detailHorizontalPadding,
                                            ownerLink: link,
                                            acquisitionService: dependencies.acquisitionService,
                                            requestActivityService: dependencies.requestActivityService,
                                            transcriptSourceLoader: dependencies.transcriptSourceLoader,
                                            onAcquisitionMutated: refreshAfterAcquisitionMutation,
                                            onEntityPruned: handlePrunedEntity,
                                            actions: {
                                                EntityDetailPlatformActionsView(
                                                    presentation: presentation,
                                                    palette: artworkPalette,
                                                    horizontalPadding: detailHorizontalPadding,
                                                    isActionSupported: isSupported,
                                                    isActionEnabled: isEnabled,
                                                    actionHint: accessibilityHint,
                                                    onAction: perform
                                                )
                                            }
                                        )
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            )

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

            fullscreenVideoPlaybackView(
                detail,
                ownerLink: playbackOwnerLink
            )
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
