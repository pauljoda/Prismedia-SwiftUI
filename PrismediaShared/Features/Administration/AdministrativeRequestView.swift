import SwiftUI

struct AdministrativeRequestView: View {
    @State private var plugins: [AdministrativePlugin] = []
    @State private var selectedKind = AdministrativeRequestKind.movie
    @State private var selectedPluginID = ""
    @State private var fieldValues: [String: String] = [:]
    @State private var results: [AdministrativeRequestSearchResult] = []
    @State private var providerErrors: [AdministrativeRequestProviderError] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    private let service: any AdministrationServicing

    init(service: any AdministrationServicing) { self.service = service }

    var body: some View {
        NavigationStack {
            List {
                Section("Search") {
                    Picker("Media type", selection: $selectedKind) {
                        ForEach(AdministrativeRequestKind.allCases) { kind in Text(kind.title).tag(kind) }
                    }
                    .disabled(isLoading)
                    Picker("Plugin", selection: $selectedPluginID) {
                        ForEach(compatiblePlugins) { plugin in Text(plugin.name).tag(plugin.id) }
                    }
                    .disabled(isLoading)
                    ForEach(searchFields) { field in
                        TextField(field.placeholder ?? field.label, text: fieldBinding(for: field.key))
                            .prismediaTextInputStyle(surface: .embedded)
                            .textContentType(.none)
                            .disabled(isLoading)
                    }
                    Button {
                        Task { await search() }
                    } label: {
                        FullWidthButtonLabel {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    }
                    .disabled(!canSearch || isLoading)
                }

                if !providerErrors.isEmpty {
                    Section("Provider Warnings") {
                        ForEach(providerErrors) { warning in
                            LabeledContent(warning.displayName, value: warning.message)
                        }
                    }
                }

                Section("Results") {
                    ForEach(results) { result in
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            HStack {
                                Text(result.title)
                                if let year = result.year { Text(year.formatted()).foregroundStyle(.secondary) }
                            }
                            if let subtitle = result.subtitle {
                                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Text(result.providerName ?? result.source).font(.caption).foregroundStyle(.secondary)
                            Label(
                                result.requestable ? "Review and request in the web app" : "Not requestable",
                                systemImage: result.requestable ? "safari" : "nosign"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if isLoading && plugins.isEmpty {
                    PrismediaLoadingView("Loading request providers…")
                } else if isLoading {
                    ProgressView("Searching…")
                } else if results.isEmpty && !plugins.isEmpty {
                    ContentUnavailableView(
                        "Search for Media", systemImage: "paperplane",
                        description: Text(
                            "Native discovery is available. Proposal review and commit remain in the web app until their full selection contract is represented safely."
                        ))
                }
            }
            .navigationTitle("Request")
            .alert(
                "Request Search Unavailable",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .task { await loadPlugins() }
        .onChange(of: selectedKind) {
            fieldValues = [:]
            selectFirstPlugin()
        }
        .onChange(of: selectedPluginID) { fieldValues = [:] }
        .accessibilityIdentifier("administration.request")
    }

    private var compatiblePlugins: [AdministrativePlugin] {
        plugins.filter { plugin in
            plugin.installed && plugin.enabled && plugin.missingAuthKeys.isEmpty
                && plugin.supports.contains {
                    $0.entityKind == selectedKind.entityKind && $0.actions.contains("search") && $0.search != nil
                }
        }
    }

    private var searchFields: [AdministrativePluginSearchField] {
        compatiblePlugins.first(where: { $0.id == selectedPluginID })?.supports.first(where: {
            $0.entityKind == selectedKind.entityKind && $0.actions.contains("search")
        })?.search?.fields ?? []
    }

    private var canSearch: Bool {
        !selectedPluginID.isEmpty
            && searchFields.allSatisfy {
                !$0.required || !(fieldValues[$0.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }

    private func fieldBinding(for key: String) -> Binding<String> {
        Binding(get: { fieldValues[key, default: ""] }, set: { fieldValues[key] = $0 })
    }

    private func loadPlugins() async {
        isLoading = true
        defer { isLoading = false }
        do {
            plugins = try await service.plugins()
            selectFirstPlugin()
        } catch { errorMessage = error.localizedDescription }
    }

    private func selectFirstPlugin() {
        if !compatiblePlugins.contains(where: { $0.id == selectedPluginID }) {
            selectedPluginID = compatiblePlugins.first?.id ?? ""
        }
    }

    private func search() async {
        let requestedKind = selectedKind
        let requestedPluginID = selectedPluginID
        let requestedFields = fieldValues
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.searchRequests(
                kind: requestedKind.rawValue,
                pluginID: requestedPluginID,
                fields: requestedFields
            )
            guard
                requestedKind == selectedKind,
                requestedPluginID == selectedPluginID,
                !Task.isCancelled
            else { return }
            results = response.results
            providerErrors = response.providerErrors
        } catch {
            guard requestedKind == selectedKind, requestedPluginID == selectedPluginID else { return }
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
    #Preview { AdministrativeRequestView(service: AdministrativePreviewService()) }
#endif
