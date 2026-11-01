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
                detailLayout(
                    detail,
                    presentation: presentation,
                    showsHeroArtwork: showsHeroArtwork,
                    paletteArtworkPath: paletteArtworkPath,
                    playbackOwnerLink: playbackOwnerLink
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .refreshable {
                    await PrismediaRefreshAction.perform {
                        await refreshDetailContent()
                    }
                }
                .task(id: detail.id) {
                    let progressLoad = bookProgressLoadingState.begin()
                    defer { bookProgressLoadingState.finish(progressLoad) }
                    // A Book's alignment decides its progress card and resume targets, so it loads first.
                    await loadBookAlignment(for: detail)
                    await loadResolvedVideoTechnicalDetail(for: detail)
                    await loadVideoProgress(for: detail)
                    await loadReadingState(for: detail)
                    await loadCollectionMembers(for: detail)
                    await loadAudiobook(for: detail)
                    await loadBookChapters(for: detail)
                    #if os(iOS) || os(macOS)
                        if let currentDetail, currentDetail.id == detail.id {
                            await promoteLegacyAudiobookProgressIfNeeded(for: currentDetail)
                        }
                    #endif
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

    /// One column on compact width and wherever the page is narrow or tall;
    /// on a wide regular-width page, the overview and progress in one pane and
    /// the sections in the other, each on its own side of iPhone Duo's fold.
    @ViewBuilder
    private func detailLayout(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation,
        showsHeroArtwork: Bool,
        paletteArtworkPath: String?,
        playbackOwnerLink: EntityLink?
    ) -> some View {
        #if os(iOS)
            if horizontalSizeClass == .regular {
                PrismediaWidePanes {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            overview(
                                detail,
                                presentation: presentation,
                                showsHeroArtwork: showsHeroArtwork,
                                paletteArtworkPath: paletteArtworkPath,
                                playbackOwnerLink: playbackOwnerLink
                            )
                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                                progressCards(detail)
                            }
                            .padding(.vertical, PrismediaSpacing.section)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } secondary: {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                            sections(detail, presentation: presentation)
                            if selectedSection == .details {
                                mainSupplementView(for: detail)
                            }
                            bottomMarker
                        }
                        .padding(.vertical, PrismediaSpacing.section)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } combined: {
                    singleColumn(
                        detail,
                        presentation: presentation,
                        showsHeroArtwork: showsHeroArtwork,
                        paletteArtworkPath: paletteArtworkPath,
                        playbackOwnerLink: playbackOwnerLink
                    )
                }
            } else {
                singleColumn(
                    detail,
                    presentation: presentation,
                    showsHeroArtwork: showsHeroArtwork,
                    paletteArtworkPath: paletteArtworkPath,
                    playbackOwnerLink: playbackOwnerLink
                )
            }
        #else
            singleColumn(
                detail,
                presentation: presentation,
                showsHeroArtwork: showsHeroArtwork,
                paletteArtworkPath: paletteArtworkPath,
                playbackOwnerLink: playbackOwnerLink
            )
        #endif
    }

    private func singleColumn(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation,
        showsHeroArtwork: Bool,
        paletteArtworkPath: String?,
        playbackOwnerLink: EntityLink?
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                overview(
                    detail,
                    presentation: presentation,
                    showsHeroArtwork: showsHeroArtwork,
                    paletteArtworkPath: paletteArtworkPath,
                    playbackOwnerLink: playbackOwnerLink
                )

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                    EntityDetailPlatformContentLayout(
                        selectedSection: selectedSection,
                        browseContent: {
                            mainSupplementView(for: detail)
                        },
                        secondaryContent: {
                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                                progressCards(detail)
                                sections(detail, presentation: presentation)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    )

                    bottomMarker
                }
                .padding(.top, PrismediaSpacing.section)
                .padding(.bottom, PrismediaSpacing.section)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// The artwork, title, rating and primary actions.
    private func overview(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation,
        showsHeroArtwork: Bool,
        paletteArtworkPath: String?,
        playbackOwnerLink: EntityLink?
    ) -> some View {
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
                            loadingActionID: pendingVideoPlaybackActionID,
                            canMutate: service.canMutate,
                            isActionEnabled: isEnabled,
                            actionHint: accessibilityHint,
                            onRatingChange: ratingDidChange,
                            onAction: perform
                        )
                    }
                },
                playback: {
                    #if os(macOS)
                        inlineVideoPlaybackView(
                            detail,
                            ownerLink: playbackOwnerLink
                        )
                    #else
                        televisionVideoPlaybackActions(
                            detail,
                            ownerLink: playbackOwnerLink
                        )
                    #endif
                }
            )
        }
    }

    /// Video, book and listening progress, plus a comic's page thumbnails.
    @ViewBuilder
    private func progressCards(_ detail: EntityDetail) -> some View {
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
                chaptersErrorMessage: bookChaptersErrorMessage
                    ?? bookAlignmentState.errorMessage,
                chapterProgressLabel: bookChapterProgressLabel(for: detail),
                horizontalPadding: detailHorizontalPadding,
                onContinueReading: {
                    if readingState.requiresResetBeforeReading {
                        Task { await startReadingOver(openReaderWhenReady: true) }
                    } else {
                        Task { await continueReading(for: detail) }
                    }
                },
                onResumeReading: { Task { await continueReading(for: detail) } },
                onContinueListening: { Task { await continueListening(to: detail) } },
                onContinueCombined: { Task { await openCombinedReader(for: detail) } },
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
                onRetryChapters: { Task { await retryBookChapterRows(for: detail) } },
                onDismissChaptersError: { bookAlignmentState.dismissError() }
            )
            .equatable()

            if detail.kind == .comicInstallment,
                let pages = readingState.manifest?.pages,
                !pages.isEmpty,
                let readerService = dependencies.readerService
            {
                ComicPageThumbnailGrid(
                    pages: pages,
                    service: readerService,
                    horizontalPadding: detailHorizontalPadding,
                    onSelect: { openReader(command: .page($0)) }
                )
            }
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
    }

    /// The section picker and the selected section's panel.
    private func sections(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation
    ) -> some View {
        EntityDetailSectionContentView(
            presentation: presentation,
            selection: $selectedSection,
            horizontalPadding: detailHorizontalPadding,
            support: EntityDetailSectionSupport(
                ownerLink: link,
                dependencies: dependencies,
                onAcquisitionMutated: refreshAfterAcquisitionMutation,
                onEntityPruned: handlePrunedEntity,
                onEnterReleaseDate: presentReleaseDateEditor,
                chapterMapping: bookChapterMappingEditorPresentation(for: detail),
                onSaveChapterMappings: { mappings in
                    try await saveBookChapterMappings(
                        mappings,
                        for: detail
                    )
                }
            ),
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

    /// Lets UI tests scroll a detail page to its end.
    private var bottomMarker: some View {
        Color.clear
            .frame(height: 1)
            .id("entity-detail.bottom")
            .accessibilityHidden(true)
    }
}
