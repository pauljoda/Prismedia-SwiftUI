#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Request & Identify Review · Search · Initial Loading") {
        RequestIdentifyFlowSheet(
            mode: .request,
            phase: .initialDependencyLoading
        ) {
            PrismediaLoadingView("Loading request providers…")
                .navigationTitle("Request")
        }
    }

    #Preview("Request & Identify Review · Search · Request · Type Selection") {
        @Previewable @State var kind: RequestKindDefinition?
        List {
            RequestKindSelector(selection: $kind, isDisabled: false)
            Section {
                ContentUnavailableView(
                    "Choose a Media Type",
                    systemImage: "square.grid.2x2",
                    description: Text("Select a type to see its available providers and search fields.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            }
        }
        .prismediaScreenBackground()
    }

    #Preview("Request & Identify Review · Search · Request · Schema Controls") {
        @Previewable @State var kind: RequestKindDefinition? = .movie
        @Previewable @State var providerID = "schema"
        @Previewable @State var values = ["query": "Arrival", "year": "2016", "edition": "1"]
        PluginSearchSurface(
            description: "Choose a source, enter its fields, then review the match.",
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.schemaProvider],
            selectedProviderID: $providerID,
            values: $values,
            onSearch: { _ in },
            onCandidateActivate: { _ in },
            leadingContent: {
                RequestKindSelector(selection: $kind, isDisabled: false)
            }
        )
    }

    #Preview("Request & Identify Review · Search · Request · Validation") {
        @Previewable @State var kind: RequestKindDefinition? = .movie
        @Previewable @State var providerID = "schema"
        @Previewable @State var values = ["query": "Arrival", "year": "99", "edition": "second"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.schemaProvider],
            selectedProviderID: $providerID,
            values: $values,
            onSearch: { _ in },
            onCandidateActivate: { _ in },
            leadingContent: {
                RequestKindSelector(selection: $kind, isDisabled: false)
            }
        )
    }

    #Preview("Request & Identify Review · Search · Request · Searching") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Arrival", "year": "2016"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            isSearching: true,
            searchStatus: "Searching with The Movie Database…",
            onSearch: { _ in },
            onCandidateActivate: { _ in }
        )
    }

    #Preview("Request & Identify Review · Search · Request · Results and Warning") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Arrival", "year": "2016"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            candidates: PluginSearchPreviewFixtures.candidates,
            hasSearched: true,
            notices: ["Legacy Provider: One provider returned a partial response."],
            onSearch: { _ in },
            onCandidateActivate: { _ in },
            onLoadMore: {}
        )
    }

    #Preview("Request & Identify Review · Search · Request · Empty") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Unknown title"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            hasSearched: true,
            onSearch: { _ in },
            onCandidateActivate: { _ in }
        )
    }

    #Preview("Request & Identify Review · Search · Request · Error and Retry") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Arrival"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            hasSearched: true,
            errorMessage: "The provider could not be reached.",
            onSearch: { _ in },
            onCandidateActivate: { _ in },
            onRetry: {}
        )
    }

    #Preview("Request & Identify Review · Search · Request · Retained Results Refresh") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Arrival"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            candidates: PluginSearchPreviewFixtures.candidates,
            hasSearched: true,
            isSearching: true,
            searchStatus: "Updating candidates…",
            onSearch: { _ in },
            onCandidateActivate: { _ in }
        )
    }

    #Preview("Request & Identify Review · Search · Request · Pagination") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Arrival"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            candidates: PluginSearchPreviewFixtures.candidates,
            hasSearched: true,
            onSearch: { _ in },
            onCandidateActivate: { _ in },
            onLoadMore: {},
            isLoadingMore: true
        )
    }

    #Preview("Request & Identify Review · Search · Unavailable Provider") {
        @Previewable @State var providerID = ""
        @Previewable @State var values: [String: String] = [:]
        PluginSearchSurface(
            noProvidersMessage: "Install, enable, or configure a compatible provider to continue.",
            entityKind: "movie",
            providers: [],
            selectedProviderID: $providerID,
            values: $values,
            onSearch: { _ in },
            onCandidateActivate: { _ in },
            onRetry: {}
        )
    }

    #Preview("Request & Identify Review · Search · Identify · Restored Results") {
        IdentifySearchView(
            session: IdentifySession(
                service: AdministrativePreviewService(),
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [IdentifyPreviewFixtures.searchItem],
                initialProviders: [IdentifyPreviewFixtures.provider],
                initialDefaultProviderIDs: ["movie": "tmdb"]
            ),
            item: IdentifyPreviewFixtures.searchItem
        )
    }

    #Preview("Request & Identify Review · Search · Identify · Review Transition Failure") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Arrival", "year": "2016"]
        PluginSearchSurface(
            title: "Find Metadata",
            entityKind: "movie",
            seedTitle: "Arrival",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            candidates: PluginSearchPreviewFixtures.candidates,
            hasSearched: true,
            errorMessage: "The selected match could not be prepared for review.",
            activeCandidateID: PluginSearchPreviewFixtures.candidates[0].pluginSearchIdentity,
            onSearch: { _ in },
            onCandidateActivate: { _ in },
            onCandidatePreview: { _ in },
            onRetry: {},
            onRescan: {},
            onSeek: {}
        )
    }

    #Preview("Request & Identify Review · Search · Safe Unknown State") {
        RequestIdentifyFlowSheet(
            mode: .identify,
            phase: .unknown("waiting-for-provider")
        ) {
            ContentUnavailableView {
                Label("Waiting for Identify", systemImage: "hourglass")
            } description: {
                Text("A newer server state was received. Existing search information remains safe to refresh.")
            } actions: {
                PrismediaButton("Refresh", systemImage: "arrow.clockwise") {}
            }
            .navigationTitle("Identify")
        }
    }

    #Preview("Request & Identify Review · Search · Accessibility") {
        @Previewable @State var providerID = "tmdb"
        @Previewable @State var values = ["query": "Arrival", "year": "2016"]
        PluginSearchSurface(
            entityKind: "movie",
            providers: [PluginSearchPreviewFixtures.provider],
            selectedProviderID: $providerID,
            values: $values,
            candidates: PluginSearchPreviewFixtures.candidates,
            hasSearched: true,
            onSearch: { _ in },
            onCandidateActivate: { _ in }
        )
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
