import SwiftUI

#if os(iOS) || os(macOS)
    struct PluginSearchSurface: View {
        private let title: String
        private let description: String?
        private let providerLabel: String
        private let noProvidersMessage: String
        private let entityKind: String
        private let hidesNsfw: Bool
        private let seedTitle: String
        private let providers: [AdministrativePlugin]
        @Binding private var selectedProviderID: String
        @Binding private var values: [String: String]
        private let candidates: [AdministrativeEntitySearchCandidate]
        private let hasSearched: Bool
        private let isSearching: Bool
        private let isDisabled: Bool
        private let submitDisabled: Bool
        private let errorMessage: String?
        private let searchStatus: String?
        private let notices: [String]
        private let activeCandidateID: PluginSearchCandidateIdentity?
        private let onProviderChange: ((String) -> Void)?
        private let onSearch: ([String: String]) -> Void
        private let onClear: (() -> Void)?
        private let onCandidateActivate: (AdministrativeEntitySearchCandidate) -> Void
        private let onCandidatePreview: ((AdministrativeEntitySearchCandidate) -> Void)?
        private let onRescan: (() -> Void)?
        private let isRescanning: Bool
        private let onSeek: (() -> Void)?
        private let isSeeking: Bool

        init(
            title: String = "Search",
            description: String? = nil,
            providerLabel: String = "Provider",
            noProvidersMessage: String = "No enabled provider supports this content kind.",
            entityKind: String,
            hidesNsfw: Bool,
            seedTitle: String = "",
            providers: [AdministrativePlugin],
            selectedProviderID: Binding<String>,
            values: Binding<[String: String]>,
            candidates: [AdministrativeEntitySearchCandidate] = [],
            hasSearched: Bool = false,
            isSearching: Bool = false,
            isDisabled: Bool = false,
            submitDisabled: Bool = false,
            errorMessage: String? = nil,
            searchStatus: String? = nil,
            notices: [String] = [],
            activeCandidateID: PluginSearchCandidateIdentity? = nil,
            onProviderChange: ((String) -> Void)? = nil,
            onSearch: @escaping ([String: String]) -> Void,
            onClear: (() -> Void)? = nil,
            onCandidateActivate: @escaping (AdministrativeEntitySearchCandidate) -> Void,
            onCandidatePreview: ((AdministrativeEntitySearchCandidate) -> Void)? = nil,
            onRescan: (() -> Void)? = nil,
            isRescanning: Bool = false,
            onSeek: (() -> Void)? = nil,
            isSeeking: Bool = false
        ) {
            self.title = title
            self.description = description
            self.providerLabel = providerLabel
            self.noProvidersMessage = noProvidersMessage
            self.entityKind = entityKind
            self.hidesNsfw = hidesNsfw
            self.seedTitle = seedTitle
            self.providers = providers
            _selectedProviderID = selectedProviderID
            _values = values
            self.candidates = candidates
            self.hasSearched = hasSearched
            self.isSearching = isSearching
            self.isDisabled = isDisabled
            self.submitDisabled = submitDisabled
            self.errorMessage = errorMessage
            self.searchStatus = searchStatus
            self.notices = notices
            self.activeCandidateID = activeCandidateID
            self.onProviderChange = onProviderChange
            self.onSearch = onSearch
            self.onClear = onClear
            self.onCandidateActivate = onCandidateActivate
            self.onCandidatePreview = onCandidatePreview
            self.onRescan = onRescan
            self.isRescanning = isRescanning
            self.onSeek = onSeek
            self.isSeeking = isSeeking
        }

        var body: some View {
            List {
                searchSection
                noticesSection
                candidateSection
            }
            .prismediaScreenBackground()
            .onChange(of: eligibleProviders.map(\.id), initial: true) { _, _ in
                reconcileProviderSelection()
            }
            .onChange(of: searchFields, initial: true) { _, fields in
                values = PluginSearchFieldPolicy.seedValues(
                    for: fields,
                    existing: values,
                    title: seedTitle
                )
            }
            .accessibilityIdentifier("plugin-search.surface")
        }

        @ViewBuilder
        private var noticesSection: some View {
            if !notices.isEmpty {
                Section("Provider Warnings") {
                    ForEach(notices, id: \.self) { notice in
                        Label(notice, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(PrismediaColor.warning)
                    }
                }
                .accessibilityIdentifier("plugin-search.warnings")
            }
        }

        private var searchSection: some View {
            Section {
                if activeProvider != nil {
                    LabeledContent(providerLabel) {
                        Picker(providerLabel, selection: providerSelection) {
                            ForEach(eligibleProviders) { provider in
                                Text(provider.name).tag(provider.id)
                            }
                        }
                        .labelsHidden()
                    }
                    .disabled(isBusy)
                    .accessibilityIdentifier("plugin-search.provider")

                    ForEach(searchFields) { field in
                        PluginSearchFieldControl(
                            field: field,
                            value: fieldBinding(field.key),
                            isDisabled: isBusy
                        )
                    }

                    actionRow

                    if let searchStatus, !searchStatus.isEmpty {
                        Label(searchStatus, systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("plugin-search.status")
                    }

                    providerActions
                } else {
                    ContentUnavailableView(
                        "No Search Providers",
                        systemImage: "puzzlepiece.extension",
                        description: Text(noProvidersMessage)
                    )
                    .accessibilityIdentifier("plugin-search.no-provider")
                }
            } header: {
                Label(title, systemImage: "magnifyingglass")
            } footer: {
                if let description, !description.isEmpty {
                    Text(description)
                } else if let activeProvider {
                    Text("Searching with \(activeProvider.name)")
                }
            }
        }

        @ViewBuilder
        private var providerActions: some View {
            if onRescan != nil || onSeek != nil {
                HStack(spacing: PrismediaSpacing.medium) {
                    if let onRescan {
                        Button(
                            isRescanning ? "Rescanning" : "Rescan",
                            systemImage: "arrow.clockwise",
                            action: onRescan
                        )
                        .disabled(isBusy)
                    }
                    if let onSeek {
                        Button(
                            isSeeking ? "Seeking" : "Seek All",
                            systemImage: "scope",
                            action: onSeek
                        )
                        .disabled(isBusy)
                    }
                }
            }
        }

        private var actionRow: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Button("Clear", systemImage: "xmark") {
                    values = Dictionary(uniqueKeysWithValues: searchFields.map { ($0.key, "") })
                    onClear?()
                }
                .buttonStyle(.glass)
                .disabled(isBusy || values.values.allSatisfy(\.isEmpty))

                Spacer()

                Button(isSearching ? "Searching" : "Search", systemImage: "magnifyingglass") {
                    onSearch(
                        PluginSearchFieldPolicy.submittedValues(
                            fields: searchFields,
                            values: values
                        ))
                }
                .buttonStyle(.glassProminent)
                .disabled(!canSearch)
                .accessibilityIdentifier("plugin-search.submit")
            }
        }

        private var candidateSection: some View {
            Section {
                candidateContent
            } header: {
                HStack {
                    Text("Candidates")
                    Spacer(minLength: 0)
                    if case .results(let count) = presentationState {
                        Text("\(count) found")
                    }
                }
            }
            .accessibilityIdentifier("plugin-search.candidates")
        }

        @ViewBuilder
        private var candidateContent: some View {
            switch presentationState {
            case .noProvider:
                ContentUnavailableView(
                    "No Provider",
                    systemImage: "puzzlepiece.extension",
                    description: Text(noProvidersMessage)
                )
            case .preSearch:
                ContentUnavailableView(
                    "Search for a Match",
                    systemImage: "magnifyingglass",
                    description: Text("Enter the provider-specific details above to find candidates.")
                )
            case .searching:
                HStack(spacing: PrismediaSpacing.medium) {
                    ProgressView()
                    Text("Searching \(activeProvider?.name ?? "provider")…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("plugin-search.searching")
            case .noResults:
                ContentUnavailableView(
                    "No Candidates Found",
                    systemImage: "magnifyingglass",
                    description: Text("Try another provider or refine the search fields.")
                )
            case .results:
                ForEach(candidates, id: \.pluginSearchIdentity) { candidate in
                    PluginCandidateCard(
                        candidate: candidate,
                        isBestMatch: candidate.pluginSearchIdentity == candidates.first?.pluginSearchIdentity,
                        isActive: candidate.pluginSearchIdentity == activeCandidateID,
                        isDisabled: isBusy,
                        onActivate: { onCandidateActivate(candidate) },
                        onPreview: onCandidatePreview.map { preview in
                            { preview(candidate) }
                        }
                    )
                }
            case .error(let message):
                ContentUnavailableView(
                    "Search Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .accessibilityIdentifier("plugin-search.error")
            }
        }

        private var eligibleProviders: [AdministrativePlugin] {
            PluginSearchFieldPolicy.eligibleProviders(
                providers,
                entityKind: entityKind,
                hidesNsfw: hidesNsfw
            )
        }

        private var activeProvider: AdministrativePlugin? {
            eligibleProviders.first { $0.id == selectedProviderID } ?? eligibleProviders.first
        }

        private var searchFields: [AdministrativePluginSearchField] {
            activeProvider
                .flatMap { PluginSearchFieldPolicy.support(in: $0, entityKind: entityKind) }?
                .search?.fields ?? []
        }

        private var presentationState: PluginSearchPresentationState {
            PluginSearchPresentationState.resolve(
                hasProvider: activeProvider != nil,
                isSearching: isSearching,
                hasSearched: hasSearched,
                candidateCount: candidates.count,
                errorMessage: errorMessage
            )
        }

        private var canSearch: Bool {
            activeProvider != nil
                && !searchFields.isEmpty
                && !isBusy
                && !submitDisabled
                && PluginSearchFieldPolicy.hasRequiredValues(fields: searchFields, values: values)
        }

        private var isBusy: Bool {
            isDisabled || isSearching || isRescanning || isSeeking
        }

        private var providerSelection: Binding<String> {
            Binding(
                get: { activeProvider?.id ?? selectedProviderID },
                set: { providerID in
                    guard providerID != selectedProviderID else { return }
                    selectedProviderID = providerID
                    let fields =
                        eligibleProviders
                        .first { $0.id == providerID }
                        .flatMap { PluginSearchFieldPolicy.support(in: $0, entityKind: entityKind) }?
                        .search?.fields ?? []
                    values = PluginSearchFieldPolicy.seedValues(for: fields, existing: [:], title: seedTitle)
                    onProviderChange?(providerID)
                }
            )
        }

        private func fieldBinding(_ key: String) -> Binding<String> {
            Binding(
                get: { values[key, default: ""] },
                set: { values[key] = $0 }
            )
        }

        private func reconcileProviderSelection() {
            let nextProviderID = activeProvider?.id ?? ""
            guard nextProviderID != selectedProviderID else { return }
            selectedProviderID = nextProviderID
            onProviderChange?(nextProviderID)
        }
    }

    #if DEBUG
        #Preview("Plugin Search · Content") {
            @Previewable @State var providerID = "tmdb"
            @Previewable @State var values = ["query": "Arrival", "year": "2016"]
            PreviewShell {
                PluginSearchSurface(
                    title: "Discover",
                    description: "Choose a source and search",
                    entityKind: "movie",
                    hidesNsfw: true,
                    providers: [PluginSearchPreviewFixtures.provider, PluginSearchPreviewFixtures.secondProvider],
                    selectedProviderID: $providerID,
                    values: $values,
                    candidates: PluginSearchPreviewFixtures.candidates,
                    hasSearched: true,
                    activeCandidateID: PluginSearchPreviewFixtures.candidates[0].pluginSearchIdentity,
                    onSearch: { _ in },
                    onCandidateActivate: { _ in },
                    onCandidatePreview: { _ in },
                    onRescan: {},
                    onSeek: {}
                )
            }
        }

        #Preview("Plugin Search · Loading") {
            @Previewable @State var providerID = "tmdb"
            @Previewable @State var values = ["query": "Arrival"]
            PreviewShell {
                PluginSearchSurface(
                    entityKind: "movie",
                    hidesNsfw: true,
                    providers: [PluginSearchPreviewFixtures.provider],
                    selectedProviderID: $providerID,
                    values: $values,
                    isSearching: true,
                    searchStatus: "Waiting for The Movie Database…",
                    onSearch: { _ in },
                    onCandidateActivate: { _ in }
                )
                .padding()
            }
        }

        #Preview("Plugin Search · Empty") {
            @Previewable @State var providerID = "tmdb"
            @Previewable @State var values = ["query": "Unknown title"]
            PreviewShell {
                PluginSearchSurface(
                    entityKind: "movie",
                    hidesNsfw: true,
                    providers: [PluginSearchPreviewFixtures.provider],
                    selectedProviderID: $providerID,
                    values: $values,
                    hasSearched: true,
                    onSearch: { _ in },
                    onCandidateActivate: { _ in }
                )
                .padding()
            }
        }

        #Preview("Plugin Search · No Provider") {
            @Previewable @State var providerID = ""
            @Previewable @State var values: [String: String] = [:]
            PreviewShell {
                PluginSearchSurface(
                    entityKind: "movie",
                    hidesNsfw: true,
                    providers: [],
                    selectedProviderID: $providerID,
                    values: $values,
                    onSearch: { _ in },
                    onCandidateActivate: { _ in }
                )
                .padding()
            }
        }

        #Preview("Plugin Search · Error") {
            @Previewable @State var providerID = "tmdb"
            @Previewable @State var values = ["query": "Arrival"]
            PreviewShell {
                PluginSearchSurface(
                    entityKind: "movie",
                    hidesNsfw: true,
                    providers: [PluginSearchPreviewFixtures.provider],
                    selectedProviderID: $providerID,
                    values: $values,
                    errorMessage: "The provider could not be reached.",
                    onSearch: { _ in },
                    onCandidateActivate: { _ in }
                )
                .padding()
            }
        }

        #Preview("Plugin Search · Dark") {
            @Previewable @State var providerID = "tmdb"
            @Previewable @State var values = ["query": "Arrival"]
            PreviewShell {
                PluginSearchSurface(
                    entityKind: "movie",
                    hidesNsfw: true,
                    providers: [PluginSearchPreviewFixtures.provider],
                    selectedProviderID: $providerID,
                    values: $values,
                    candidates: PluginSearchPreviewFixtures.candidates,
                    hasSearched: true,
                    onSearch: { _ in },
                    onCandidateActivate: { _ in }
                )
                .padding()
                .preferredColorScheme(.dark)
            }
        }

        #Preview("Plugin Search · Accessibility") {
            @Previewable @State var providerID = "tmdb"
            @Previewable @State var values = ["query": "Arrival"]
            PreviewShell {
                PluginSearchSurface(
                    entityKind: "movie",
                    hidesNsfw: true,
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
        }
    #endif
#endif
