import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifySearchView: View {
        @Bindable var session: IdentifySession
        let item: AdministrativeIdentifyQueueItem
        @State private var previewCandidate: AdministrativeEntitySearchCandidate?

        var body: some View {
            PluginSearchSurface(
                title: "Find Metadata",
                description: "Search installed plugins and choose the correct match.",
                entityKind: item.entityKind.rawValue,
                seedTitle: item.title,
                providers: session.providersForSelectedItem,
                selectedProviderID: providerSelection,
                values: $session.searchValues,
                candidates: candidates,
                hasSearched: hasSearched,
                isSearching: session.isSearching,
                isDisabled: item.cascadeRunning || session.isResolving,
                submitDisabled: submittedSearchValuesAreEmpty,
                errorMessage: session.errorMessage ?? item.error,
                searchStatus: searchStatus,
                notices: safeUnknownNotice.map { [$0] } ?? [],
                activeCandidateID: session.activeCandidateID,
                onSearch: { values in
                    Task { await session.search(fields: values) }
                },
                onClear: {
                    session.searchValues.removeAll()
                },
                onCandidateActivate: { candidate in
                    Task { await session.resolve(candidate) }
                },
                onCandidatePreview: { candidate in
                    previewCandidate = candidate
                },
                onLoadMore: session.canLoadMoreSearchCandidates
                    ? { Task { await session.loadMoreSearchCandidates() } }
                    : nil,
                isLoadingMore: session.isLoadingMore,
                onRetry: {
                    Task {
                        if session.providersForSelectedItem.isEmpty {
                            await session.refreshProviders()
                        } else {
                            await session.retryLastSearchOperation()
                        }
                    }
                },
                onRescan: {
                    Task { await session.rescan() }
                },
                isRescanning: session.isRescanning,
                onSeek: {
                    Task { await session.seek() }
                },
                isSeeking: session.isSeeking
            )
            .safeAreaInset(edge: .top, spacing: 0) {
                IdentifyTargetContextBar(
                    item: item,
                    thumbnail: session.selectedEntityThumbnail,
                    isLoading: session.isLoadingSelectedEntityDetail
                )
                .padding(.horizontal)
                .padding(.bottom, PrismediaSpacing.small)
            }
            .task(id: item.entityID) {
                await session.loadSelectedEntityDetail()
            }
            .sheet(isPresented: artworkPreviewPresentation) {
                NavigationStack {
                    if let previewCandidate {
                        RemotePosterImage(
                            path: ProviderImagePreviewPolicy.previewURL(for: previewCandidate.posterURL),
                            fallbackSeed: previewCandidate.title,
                            systemImage: "photo",
                            contentMode: .fit
                        )
                        .aspectRatio(2.0 / 3.0, contentMode: .fit)
                        .padding(PrismediaSpacing.extraLarge)
                        .background(PrismediaBackdrop())
                        .navigationTitle(previewCandidate.title)
                        #if os(iOS)
                            .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                PrismediaToolbarActionButton("Close", systemImage: "xmark") {
                                    self.previewCandidate = nil
                                }
                            }
                        }
                    }
                }
            }
        }

        private var candidates: [AdministrativeEntitySearchCandidate] {
            session.searchCandidates(for: item)
        }

        private var hasSearched: Bool {
            item.query != nil
                || !candidates.isEmpty
                || IdentifyQueueState(rawServerValue: item.state) != .queued
        }

        private var submittedSearchValuesAreEmpty: Bool {
            session.searchValues.values.allSatisfy {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }

        private var providerSelection: Binding<String> {
            Binding(
                get: { session.selectedProviderID },
                set: { session.selectProvider($0) }
            )
        }

        private var artworkPreviewPresentation: Binding<Bool> {
            Binding(
                get: { previewCandidate != nil },
                set: { if !$0 { previewCandidate = nil } }
            )
        }

        private var searchStatus: String? {
            if session.isSeeking { return "Seeking across providers…" }
            if session.isLoadingMore { return "Loading more candidates…" }
            if session.isResolving || item.cascadeRunning {
                return "Match found. Identifying related items…"
            }
            if session.isRescanning { return "Rescanning with \(selectedProviderName)…" }
            if session.isSearching, !candidates.isEmpty { return "Updating candidates…" }

            switch IdentifyQueueState(rawServerValue: item.state) {
            case .queued:
                return "Queued for search"
            case .searching:
                return "Searching with \(selectedProviderName)…"
            default:
                return nil
            }
        }

        private var selectedProviderName: String {
            session.providersForSelectedItem.first {
                $0.id.caseInsensitiveCompare(session.selectedProviderID) == .orderedSame
            }?.name ?? "provider"
        }

        private var safeUnknownNotice: String? {
            guard case .unknown(let state) = IdentifyQueueState(rawServerValue: item.state) else {
                return nil
            }
            return
                "The provider reported the newer “\(state)” state. Existing search information remains available while Prismedia refreshes it."
        }
    }

    #if DEBUG
        #Preview("Identify Search") {
            IdentifySearchView(
                session: IdentifySession(
                    service: AdministrativePreviewService(),
                    browser: IdentifyPreviewEntityBrowser(),
                    initialQueue: [IdentifyPreviewFixtures.errorItem],
                    initialProviders: [IdentifyPreviewFixtures.provider]
                ),
                item: IdentifyPreviewFixtures.errorItem
            )
        }
    #endif
#endif
