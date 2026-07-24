import SwiftUI

#if os(iOS) || os(macOS)
    public struct RequestFeatureView: View {
        private let service: any RequestFeatureServicing
        private let hidesNsfw: Bool
        private let onNavigateToEntity: (RequestEntityNavigationIntent) -> Void

        @Binding private var kind: RequestKindDefinition?
        @State private var reviewRoute: RequestReviewRoute?
        @State private var providers: [AdministrativePlugin] = []
        @State private var defaultProviderIDs: [String: String] = [:]
        @State private var selectedProviderID = ""
        @State private var fieldValues: [String: String] = [:]
        @State private var results: [AdministrativeRequestSearchResult] = []
        @State private var providerWarnings: [AdministrativeRequestProviderError] = []
        @State private var hasSearched = false
        @State private var isLoadingProviders = false
        @State private var isSearching = false
        @State private var isLoadingMore = false
        @State private var errorMessage: String?
        @State private var activeCandidateID: PluginSearchCandidateIdentity?
        @State private var searchRevision = RequestLoadRevision()
        @State private var searchLimit = RequestFeatureView.searchPageSize
        @State private var submittedFields: [String: String] = [:]
        @State private var flowPhase = RequestIdentifyFlowPhase.initialDependencyLoading
        @State private var pendingNavigationIntent: RequestEntityNavigationIntent?

        private static let searchPageSize = PluginSearchPagingPolicy.pageSize
        private static let searchMaxLimit = PluginSearchPagingPolicy.maximumLimit

        public init(
            service: any AdministrationServicing,
            kind: Binding<RequestKindDefinition?> = .constant(nil),
            hidesNsfw: Bool = true,
            onNavigateToEntity: @escaping (RequestEntityNavigationIntent) -> Void = { _ in }
        ) {
            self.service = AdministrationRequestFeatureService(administration: service)
            _kind = kind
            self.hidesNsfw = hidesNsfw
            self.onNavigateToEntity = onNavigateToEntity
        }

        init(
            requestService: any RequestFeatureServicing,
            kind: Binding<RequestKindDefinition?> = .constant(nil),
            hidesNsfw: Bool = true,
            onNavigateToEntity: @escaping (RequestEntityNavigationIntent) -> Void = { _ in }
        ) {
            service = requestService
            _kind = kind
            self.hidesNsfw = hidesNsfw
            self.onNavigateToEntity = onNavigateToEntity
        }

        public var body: some View {
            Group {
                if isLoadingProviders, providers.isEmpty, !hasSearched {
                    PrismediaLoadingView("Loading request providers…")
                } else if let kind {
                    searchSurface(for: kind)
                } else {
                    kindSelectionSurface
                }
            }
            .task { await loadProviders() }
            .onReceive(NotificationCenter.default.publisher(for: AdministrativeProviderCatalogEvent.didChange)) { _ in
                Task { await loadProviders(force: true) }
            }
            .onChange(of: kind) { _, _ in resetForKindChange() }
            .sheet(
                item: $reviewRoute,
                onDismiss: finishReviewDismissal
            ) { route in
                RequestIdentifyFlowSheet(
                    mode: .request,
                    phase: flowPhase,
                    showsBackToSearch: true
                ) {
                    RequestReviewView(
                        service: service,
                        route: route,
                        hidesNsfw: hidesNsfw,
                        flowPhase: $flowPhase,
                        onNavigateToEntity: { intent in
                            pendingNavigationIntent = intent
                            reviewRoute = nil
                        }
                    )
                }
            }
            .accessibilityIdentifier("request.feature")
        }

        private func searchSurface(
            for requestKind: RequestKindDefinition
        ) -> some View {
            let loadMoreAction: (() -> Void)? = canLoadMore ? { loadMore() } : nil
            return PluginSearchSurface(
                title: "Search",
                description:
                    "Choose a source, enter the provider fields, then review a \(requestKind.label.lowercased()) match.",
                noProvidersMessage: noProviderMessage(for: requestKind),
                entityKind: requestKind.pluginEntityKind,
                providers: eligibleProviders(for: requestKind),
                selectedProviderID: $selectedProviderID,
                values: $fieldValues,
                candidates: candidates,
                hasSearched: hasSearched,
                isSearching: isSearching,
                errorMessage: errorMessage,
                searchStatus: searchStatus,
                notices: providerWarnings.map { "\($0.displayName): \($0.message)" },
                activeCandidateID: activeCandidateID,
                candidateDetail: { candidateDetail($0) },
                onProviderChange: { selectProvider($0, for: requestKind) },
                onSearch: { fields in
                    searchLimit = Self.searchPageSize
                    search(fields)
                },
                onClear: invalidateSearch,
                onCandidateActivate: activateCandidate,
                onLoadMore: loadMoreAction,
                isLoadingMore: isLoadingMore,
                onRetry: retryAction,
                leadingContent: {
                    RequestKindSelector(
                        selection: $kind,
                        isDisabled: isSearching || isLoadingMore
                    )
                }
            )
        }

        private var kindSelectionSurface: some View {
            List {
                RequestKindSelector(
                    selection: $kind,
                    isDisabled: isLoadingProviders
                )

                Section {
                    Group {
                        if let errorMessage {
                            ContentUnavailableView {
                                Label("Couldn’t Load Providers", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text(errorMessage)
                            } actions: {
                                PrismediaButton(
                                    "Try Again",
                                    systemImage: "arrow.clockwise",
                                    variant: .prominent
                                ) {
                                    Task { await loadProviders(force: true) }
                                }
                            }
                        } else {
                            ContentUnavailableView(
                                "Choose a Media Type",
                                systemImage: "square.grid.2x2",
                                description: Text(
                                    "Select a type above to see its available providers and search fields.")
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
            .prismediaScreenBackground()
            .accessibilityIdentifier("request.kind-selection")
        }

        private var candidates: [AdministrativeEntitySearchCandidate] {
            guard let kind else { return [] }
            return results.compactMap { result in
                RequestCandidatePolicy.route(for: result, kind: kind) == nil ? nil : result.pluginCandidate
            }
        }

        private func noProviderMessage(
            for kind: RequestKindDefinition
        ) -> String {
            if isLoadingProviders { return "Loading installed providers…" }
            return "No enabled, authenticated provider supports \(kind.pluralLabel.lowercased())."
        }

        private var searchStatus: String? {
            if isLoadingMore { return "Loading more candidates…" }
            if isSearching, !results.isEmpty { return "Updating candidates…" }
            if !providerWarnings.isEmpty {
                return "\(providerWarnings.count) provider warning\(providerWarnings.count == 1 ? "" : "s")"
            }
            return nil
        }

        @MainActor
        private func loadProviders(force: Bool = false) async {
            guard force || providers.isEmpty, !isLoadingProviders else { return }
            let retainsSearchContent = !providers.isEmpty || hasSearched
            isLoadingProviders = true
            errorMessage = nil
            if !retainsSearchContent {
                flowPhase = .initialDependencyLoading
            }
            do {
                providers = try await service.providers()
                defaultProviderIDs = (try? await service.defaultProviderIDs()) ?? [:]
                reconcileProviderSelection(preferConfiguredDefault: true)
                reconcileSearchPhase()
            } catch {
                errorMessage = error.localizedDescription
                flowPhase = .searchError
            }
            isLoadingProviders = false
        }

        private var canLoadMore: Bool {
            hasSearched && !results.isEmpty
                && results.count >= searchLimit
                && searchLimit < Self.searchMaxLimit
        }

        private func loadMore() {
            guard let nextLimit = PluginSearchPagingPolicy.nextLimit(after: searchLimit) else { return }
            searchLimit = nextLimit
            search(submittedFields, loadingMore: true)
        }

        private func candidateDetail(_ candidate: AdministrativeEntitySearchCandidate) -> String? {
            guard let result = results.first(where: { $0.externalID == candidate.candidateID }) else {
                return nil
            }
            var parts: [String] = []
            if let runtime = result.runtimeMinutes {
                parts.append(Duration.seconds(runtime * 60).formatted(.units(allowed: [.hours, .minutes])))
            }
            if let certification = result.certification, !certification.isEmpty {
                parts.append(certification)
            }
            if let trackCount = result.trackCount {
                parts.append("\(trackCount) tracks")
            }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }

        private func search(
            _ fields: [String: String],
            loadingMore: Bool = false
        ) {
            guard let requestKind = kind,
                let provider = eligibleProviders(for: requestKind).first(where: {
                    $0.id.caseInsensitiveCompare(selectedProviderID) == .orderedSame
                })
            else {
                return
            }
            let revision = searchRevision.advance()
            let providerID = provider.id
            submittedFields = fields
            if loadingMore {
                isLoadingMore = true
            } else {
                isSearching = true
            }
            errorMessage = nil
            providerWarnings = []
            activeCandidateID = nil
            flowPhase = .searching
            Task {
                do {
                    let response = try await service.search(
                        kind: requestKind.rawValue,
                        pluginID: providerID,
                        fields: fields,
                        limit: searchLimit
                    )
                    guard searchRevision.isCurrent(revision), kind == requestKind,
                        selectedProviderID.caseInsensitiveCompare(providerID) == .orderedSame
                    else { return }
                    results = response.results
                    providerWarnings = response.providerErrors
                    hasSearched = true
                    flowPhase = response.results.isEmpty ? .empty : .results
                } catch {
                    guard searchRevision.isCurrent(revision) else { return }
                    hasSearched = true
                    errorMessage = error.localizedDescription
                    flowPhase = .searchError
                }
                if searchRevision.isCurrent(revision) {
                    isSearching = false
                    isLoadingMore = false
                }
            }
        }

        private func activateCandidate(_ candidate: AdministrativeEntitySearchCandidate) {
            guard let kind,
                let result = results.first(where: { $0.externalID == candidate.candidateID }),
                let route = RequestCandidatePolicy.route(for: result, kind: kind)
            else { return }
            activeCandidateID = candidate.pluginSearchIdentity
            flowPhase = .selection
            reviewRoute = route
            flowPhase = .reviewLoading
        }

        private func resetForKindChange() {
            invalidateSearch()
            guard let kind else {
                selectedProviderID = ""
                fieldValues = [:]
                return
            }
            let nextProvider = eligibleProviders(for: kind).first
            selectedProviderID = nextProvider?.id ?? ""
            fieldValues = PluginSearchFieldPolicy.seedValues(
                for: searchFields(for: nextProvider, kind: kind),
                existing: [:],
                title: ""
            )
            reconcileSearchPhase()
        }

        private func invalidateSearch() {
            _ = searchRevision.advance()
            searchLimit = Self.searchPageSize
            submittedFields = [:]
            results = []
            providerWarnings = []
            hasSearched = false
            isSearching = false
            isLoadingMore = false
            errorMessage = nil
            activeCandidateID = nil
            reconcileSearchPhase()
        }

        private func retrySearch() {
            let fields =
                submittedFields.isEmpty
                ? fieldValues
                : submittedFields
            search(fields, loadingMore: searchLimit > Self.searchPageSize && !results.isEmpty)
        }

        private func retryAction() {
            if eligibleProviders.isEmpty {
                Task { await loadProviders(force: true) }
            } else {
                retrySearch()
            }
        }

        private func finishReviewDismissal() {
            let intent = pendingNavigationIntent
            pendingNavigationIntent = nil
            activeCandidateID = nil
            reconcileSearchPhase()
            if let intent {
                onNavigateToEntity(intent)
            }
        }

        private func reconcileSearchPhase() {
            if isSearching {
                flowPhase = .searching
            } else if errorMessage != nil {
                flowPhase = .searchError
            } else if hasSearched {
                flowPhase = results.isEmpty ? .empty : .results
            } else if kind == nil || hasReadyProvider {
                flowPhase = .searchReady
            } else {
                flowPhase = .unavailable
            }
        }

        private var hasReadyProvider: Bool {
            !eligibleProviders.isEmpty
        }

        private var eligibleProviders: [AdministrativePlugin] {
            guard let kind else { return [] }
            return eligibleProviders(for: kind)
        }

        private func eligibleProviders(
            for kind: RequestKindDefinition
        ) -> [AdministrativePlugin] {
            RequestIdentifyProviderPreferencePolicy.eligibleProviders(
                providers,
                entityKind: kind.pluginEntityKind,
                defaultProviderIDs: defaultProviderIDs,
                hidesNsfw: hidesNsfw
            )
        }

        private func searchFields(
            for provider: AdministrativePlugin?,
            kind: RequestKindDefinition
        ) -> [AdministrativePluginSearchField] {
            provider
                .flatMap {
                    PluginSearchFieldPolicy.searchSupport(
                        in: $0,
                        entityKind: kind.pluginEntityKind
                    )
                }?
                .search?
                .fields ?? []
        }

        private func reconcileProviderSelection(
            preferConfiguredDefault: Bool = false
        ) {
            guard let kind else {
                selectedProviderID = ""
                return
            }
            let providers = eligibleProviders(for: kind)
            let current = providers.first {
                $0.id.caseInsensitiveCompare(selectedProviderID) == .orderedSame
            }
            let nextProvider = preferConfiguredDefault ? providers.first : (current ?? providers.first)
            guard selectedProviderID != nextProvider?.id else { return }
            selectedProviderID = nextProvider?.id ?? ""
            fieldValues = PluginSearchFieldPolicy.seedValues(
                for: searchFields(for: nextProvider, kind: kind),
                existing: [:],
                title: ""
            )
        }

        private func selectProvider(
            _ providerID: String,
            for kind: RequestKindDefinition
        ) {
            let provider = eligibleProviders(for: kind).first {
                $0.id.caseInsensitiveCompare(providerID) == .orderedSame
            }
            selectedProviderID = provider?.id ?? ""
            fieldValues = PluginSearchFieldPolicy.seedValues(
                for: searchFields(for: provider, kind: kind),
                existing: [:],
                title: ""
            )
            invalidateSearch()
        }
    }

    #if DEBUG
        #Preview("Request · Content") {
            RequestFeatureView(
                requestService: RequestPreviewService(scenario: .content),
                kind: .constant(.movie)
            )
        }

        #Preview("Request · Loading") {
            RequestFeatureView(requestService: RequestPreviewService(scenario: .loading))
        }

        #Preview("Request · Empty") {
            RequestFeatureView(
                requestService: RequestPreviewService(scenario: .empty),
                kind: .constant(.movie)
            )
        }

        #Preview("Request · Error") {
            RequestFeatureView(
                requestService: RequestPreviewService(scenario: .error),
                kind: .constant(.movie)
            )
        }

        #Preview("Request · Dark") {
            RequestFeatureView(
                requestService: RequestPreviewService(scenario: .content),
                kind: .constant(.movie)
            )
            .preferredColorScheme(.dark)
        }

        #Preview("Request · Accessibility") {
            RequestFeatureView(
                requestService: RequestPreviewService(scenario: .content),
                kind: .constant(.movie)
            )
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
