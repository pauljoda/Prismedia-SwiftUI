import SwiftUI

#if os(iOS) || os(macOS)
    public struct RequestFeatureView: View {
        private let service: any RequestFeatureServicing
        private let hidesNsfw: Bool
        private let onNavigateToEntity: (RequestEntityNavigationIntent) -> Void

        @Binding private var kind: RequestKindDefinition
        @State private var reviewRoute: RequestReviewRoute?
        @State private var providers: [AdministrativePlugin] = []
        @State private var selectedProviderID = ""
        @State private var fieldValues: [String: String] = [:]
        @State private var results: [AdministrativeRequestSearchResult] = []
        @State private var providerWarnings: [AdministrativeRequestProviderError] = []
        @State private var hasSearched = false
        @State private var isLoadingProviders = false
        @State private var isSearching = false
        @State private var errorMessage: String?
        @State private var searchRevision = RequestLoadRevision()
        @State private var searchLimit = RequestFeatureView.searchPageSize
        @State private var submittedFields: [String: String] = [:]

        private static let searchPageSize = 25
        private static let searchMaxLimit = 100

        public init(
            service: any AdministrationServicing,
            kind: Binding<RequestKindDefinition> = .constant(.movie),
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
            kind: Binding<RequestKindDefinition> = .constant(.movie),
            hidesNsfw: Bool = true,
            onNavigateToEntity: @escaping (RequestEntityNavigationIntent) -> Void = { _ in }
        ) {
            service = requestService
            _kind = kind
            self.hidesNsfw = hidesNsfw
            self.onNavigateToEntity = onNavigateToEntity
        }

        public var body: some View {
            let loadMoreAction: (() -> Void)? = canLoadMore ? { loadMore() } : nil
            PluginSearchSurface(
                title: "Search",
                description: "Choose a source, enter the provider fields, then review a \(kind.label.lowercased()) match.",
                noProvidersMessage: noProviderMessage,
                entityKind: kind.pluginEntityKind,
                hidesNsfw: hidesNsfw,
                providers: providers,
                selectedProviderID: $selectedProviderID,
                values: $fieldValues,
                candidates: candidates,
                hasSearched: hasSearched,
                isSearching: isSearching || isLoadingProviders,
                errorMessage: errorMessage,
                searchStatus: providerWarnings.isEmpty
                    ? nil
                    : "\(providerWarnings.count) provider warning\(providerWarnings.count == 1 ? "" : "s")",
                notices: providerWarnings.map { "\($0.displayName): \($0.message)" },
                candidateDetail: { candidateDetail($0) },
                onProviderChange: { _ in invalidateSearch() },
                onSearch: { fields in
                    searchLimit = Self.searchPageSize
                    search(fields)
                },
                onClear: invalidateSearch,
                onCandidateActivate: activateCandidate,
                onLoadMore: loadMoreAction
            )
            .task { await loadProviders() }
            .onReceive(NotificationCenter.default.publisher(for: AdministrativeProviderCatalogEvent.didChange)) { _ in
                Task { await loadProviders(force: true) }
            }
            .onChange(of: kind) { _, _ in resetForKindChange() }
            .sheet(
                isPresented: Binding(
                    get: { reviewRoute != nil },
                    set: { if !$0 { reviewRoute = nil } }
                )
            ) {
                if let route = reviewRoute {
                    NavigationStack {
                        RequestReviewView(
                            service: service,
                            route: route,
                            hidesNsfw: hidesNsfw,
                            onNavigateToEntity: { intent in
                                reviewRoute = nil
                                onNavigateToEntity(intent)
                            }
                        )
                    }
                }
            }
            .accessibilityIdentifier("request.feature")
        }

        private var candidates: [AdministrativeEntitySearchCandidate] {
            results.compactMap { result in
                RequestCandidatePolicy.route(for: result, kind: kind) == nil ? nil : result.pluginCandidate
            }
        }

        private var noProviderMessage: String {
            if isLoadingProviders { return "Loading installed providers…" }
            return "No enabled, authenticated provider supports \(kind.pluralLabel.lowercased())."
        }

        @MainActor
        private func loadProviders(force: Bool = false) async {
            guard force || providers.isEmpty, !isLoadingProviders else { return }
            isLoadingProviders = true
            errorMessage = nil
            do {
                providers = try await service.providers()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoadingProviders = false
        }

        private var canLoadMore: Bool {
            hasSearched && !results.isEmpty
                && results.count >= searchLimit
                && searchLimit < Self.searchMaxLimit
        }

        private func loadMore() {
            searchLimit = min(searchLimit + Self.searchPageSize, Self.searchMaxLimit)
            search(submittedFields)
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

        private func search(_ fields: [String: String]) {
            let revision = searchRevision.advance()
            let providerID = selectedProviderID
            let requestKind = kind
            submittedFields = fields
            isSearching = true
            errorMessage = nil
            providerWarnings = []
            Task {
                do {
                    let response = try await service.search(
                        kind: requestKind.rawValue,
                        pluginID: providerID,
                        fields: fields,
                        limit: searchLimit
                    )
                    guard searchRevision.isCurrent(revision), kind == requestKind,
                        selectedProviderID == providerID
                    else { return }
                    results = response.results
                    providerWarnings = response.providerErrors
                    hasSearched = true
                } catch {
                    guard searchRevision.isCurrent(revision) else { return }
                    results = []
                    hasSearched = true
                    errorMessage = error.localizedDescription
                }
                if searchRevision.isCurrent(revision) { isSearching = false }
            }
        }

        private func activateCandidate(_ candidate: AdministrativeEntitySearchCandidate) {
            guard let result = results.first(where: { $0.externalID == candidate.candidateID }),
                let route = RequestCandidatePolicy.route(for: result, kind: kind)
            else { return }
            reviewRoute = route
        }

        private func resetForKindChange() {
            selectedProviderID = ""
            fieldValues = [:]
            invalidateSearch()
        }

        private func invalidateSearch() {
            _ = searchRevision.advance()
            searchLimit = Self.searchPageSize
            submittedFields = [:]
            results = []
            providerWarnings = []
            hasSearched = false
            isSearching = false
            errorMessage = nil
        }
    }

    #if DEBUG
        #Preview("Request · Content") {
            RequestFeatureView(requestService: RequestPreviewService(scenario: .content))
        }

        #Preview("Request · Loading") {
            RequestFeatureView(requestService: RequestPreviewService(scenario: .loading))
        }

        #Preview("Request · Empty") {
            RequestFeatureView(requestService: RequestPreviewService(scenario: .empty))
        }

        #Preview("Request · Error") {
            RequestFeatureView(requestService: RequestPreviewService(scenario: .error))
        }

        #Preview("Request · Dark") {
            RequestFeatureView(requestService: RequestPreviewService(scenario: .content))
                .preferredColorScheme(.dark)
        }

        #Preview("Request · Accessibility") {
            RequestFeatureView(requestService: RequestPreviewService(scenario: .content))
                .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
