import SwiftUI

#if os(iOS) || os(macOS)
    public struct RequestFeatureView: View {
        private let service: any RequestFeatureServicing
        private let hidesNsfw: Bool
        private let onNavigateToEntity: (RequestEntityNavigationIntent) -> Void

        @State private var reviewRoute: RequestReviewRoute?
        @State private var kind = RequestKindDefinition.movie
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

        public init(
            service: any AdministrationServicing,
            hidesNsfw: Bool = true,
            onNavigateToEntity: @escaping (RequestEntityNavigationIntent) -> Void = { _ in }
        ) {
            self.service = AdministrationRequestFeatureService(administration: service)
            self.hidesNsfw = hidesNsfw
            self.onNavigateToEntity = onNavigateToEntity
        }

        init(
            requestService: any RequestFeatureServicing,
            hidesNsfw: Bool = true,
            onNavigateToEntity: @escaping (RequestEntityNavigationIntent) -> Void = { _ in }
        ) {
            service = requestService
            self.hidesNsfw = hidesNsfw
            self.onNavigateToEntity = onNavigateToEntity
        }

        public var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    kindPicker

                    PluginSearchSurface(
                        title: "Discover \(kind.pluralLabel)",
                        description: "Search your installed metadata providers",
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
                        onProviderChange: { _ in invalidateSearch() },
                        onSearch: search,
                        onClear: invalidateSearch,
                        onCandidateActivate: activateCandidate
                    )

                    RequestProviderWarningsView(warnings: providerWarnings)
                }
                .padding()
            }
            .navigationTitle("Request")
            .prismediaScreenBackground()
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

        private var kindPicker: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Label("What would you like to request?", systemImage: "sparkle.magnifyingglass")
                    .font(.headline)
                Picker("Media type", selection: $kind) {
                    ForEach(RequestKindDefinition.allCases) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("request.kind")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
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

        private func search(_ fields: [String: String]) {
            let revision = searchRevision.advance()
            let providerID = selectedProviderID
            let requestKind = kind
            isSearching = true
            errorMessage = nil
            providerWarnings = []
            Task {
                do {
                    let response = try await service.search(
                        kind: requestKind.rawValue,
                        pluginID: providerID,
                        fields: fields
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
