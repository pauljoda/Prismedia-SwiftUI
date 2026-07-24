import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifySearchView: View {
        @Bindable var session: IdentifySession
        let item: AdministrativeIdentifyQueueItem

        var body: some View {
            PluginSearchSurface(
                title: "Find Metadata",
                description: "Search installed plugins and choose the correct match.",
                entityKind: item.entityKind.rawValue,
                hidesNsfw: session.hidesNsfw,
                seedTitle: item.title,
                providers: session.providers,
                selectedProviderID: $session.selectedProviderID,
                values: $session.searchValues,
                candidates: item.candidates,
                hasSearched: item.query != nil || !item.candidates.isEmpty,
                isSearching: session.isSearching,
                isDisabled: item.cascadeRunning,
                errorMessage: session.errorMessage ?? item.error,
                searchStatus: session.isSeeking ? "Seeking across providers…" : nil,
                onSearch: { values in
                    Task { await session.search(fields: values) }
                },
                onClear: {
                    session.searchValues.removeAll()
                },
                onCandidateActivate: { candidate in
                    Task { await session.resolve(candidate) }
                },
                onRescan: {
                    Task { await session.rescan() }
                },
                isRescanning: session.isSearching,
                onSeek: {
                    Task { await session.seek() }
                },
                isSeeking: session.isSeeking
            )
            .safeAreaInset(edge: .top, spacing: 0) {
                IdentifyTargetContextBar(item: item)
                    .padding(.horizontal)
                    .padding(.bottom, PrismediaSpacing.small)
            }
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
