import SwiftUI

struct AdministrativePluginsView: View {
    @State private var plugins: [AdministrativePlugin] = []
    @State private var stashScrapers: [AdministrativeStashScraper] = []
    @State private var selectedSection: AdministrativePluginsSection? = .installed
    @State private var selectedPlugin: AdministrativePlugin?
    @State private var searchText = ""
    @State private var capabilityFilter = "all"
    @State private var isLoading = true
    @State private var isRefreshingStash = false
    @State private var installingStashID: String?
    @State private var errorMessage: String?
    private let service: any PluginAdministrationServicing
    private let hidesNsfw: Bool

    init(service: any PluginAdministrationServicing, hidesNsfw: Bool) {
        self.service = service
        self.hidesNsfw = hidesNsfw
    }

    var body: some View {
        NavigationSplitView {
            List(visibleSections, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.label, systemImage: section.systemImage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
            }
            .navigationTitle("Plugins")
        } detail: {
            List {
                if selectedSection == .stashCommunity {
                    stashContent
                } else {
                    pluginContent
                }
            }
            .navigationTitle(selectedSection?.label ?? "Plugins")
            .searchable(text: $searchText, prompt: "Search plugins")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectedSection != .stashCommunity {
                        Menu("Filter Capabilities", systemImage: "line.3.horizontal.decrease.circle") {
                            Picker("Entity Kind", selection: $capabilityFilter) {
                                Text("All Capabilities").tag("all")
                                ForEach(capabilityKinds, id: \.self) { kind in Text(kind).tag(kind) }
                            }
                        }
                    }
                    Button("Refresh", systemImage: "arrow.clockwise") { Task { await refreshSelected() } }
                        .disabled(isLoading || isRefreshingStash)
                }
            }
            .overlay { emptyOrLoadingOverlay }
            .refreshable { await refreshSelected() }
        }
        .prismediaScreenBackground()
        .task { await loadCatalog() }
        .onChange(of: selectedSection) {
            searchText = ""
            capabilityFilter = "all"
            if selectedSection == .stashCommunity, stashScrapers.isEmpty { Task { await loadStash() } }
        }
        .sheet(item: $selectedPlugin) { plugin in
            AdministrativePluginDetailView(plugin: plugin, service: service) {
                Task { await loadCatalog() }
            }
        }
        .alert(
            "Plugin Action Failed",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .accessibilityIdentifier("administration.plugins")
    }

    @ViewBuilder
    private var pluginContent: some View {
        ForEach(filteredPlugins) { plugin in
            Button {
                selectedPlugin = plugin
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    HStack {
                        Text(plugin.name).font(.headline)
                        Spacer()
                        Text("v\(plugin.version)").font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: PrismediaSpacing.small) {
                        Label(
                            plugin.installed ? (plugin.enabled ? "Installed" : "Disabled") : "Available",
                            systemImage: plugin.installed ? "checkmark.circle" : "arrow.down.circle")
                        if plugin.updateAvailable {
                            Label("v\(plugin.availableVersion ?? "latest") available", systemImage: "sparkles")
                        }
                        if !plugin.missingAuthKeys.isEmpty {
                            Label("Credentials required", systemImage: "key.fill")
                                .foregroundStyle(PrismediaColor.warning)
                        }
                    }
                    .font(.caption)
                    Text(
                        plugin.supports.map { "\($0.entityKind): \($0.actions.joined(separator: ", "))" }.joined(
                            separator: "  ·  ")
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .contextMenu {
                if !plugin.installed || !plugin.enabled {
                    Button(plugin.installed ? "Enable" : "Install", systemImage: "arrow.down.circle") {
                        Task { await install(plugin.id) }
                    }
                }
                if plugin.installed, plugin.updateAvailable {
                    Button("Update", systemImage: "arrow.trianglehead.2.clockwise") { selectedPlugin = plugin }
                }
                Button("Show Details", systemImage: "info.circle") { selectedPlugin = plugin }
            }
            .accessibilityIdentifier("administration.plugins.row.\(plugin.id)")
        }
    }

    @ViewBuilder
    private var stashContent: some View {
        ForEach(filteredStashScrapers) { scraper in
            HStack {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(scraper.name).font(.headline)
                    Text("\(scraper.providerID) · \(scraper.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if installedPluginIDs.contains(scraper.providerID) {
                    Label("Installed", systemImage: "checkmark.circle")
                        .font(.caption)
                } else {
                    Button("Install", systemImage: "arrow.down.circle") { Task { await installStash(scraper) } }
                        .disabled(installingStashID != nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
    }

    @ViewBuilder
    private var emptyOrLoadingOverlay: some View {
        if isLoading, plugins.isEmpty {
            PrismediaLoadingView("Loading plugin catalog…")
        } else if selectedSection == .stashCommunity, isRefreshingStash, stashScrapers.isEmpty {
            PrismediaLoadingView("Loading Stash Community…")
        } else if selectedSection == .stashCommunity, filteredStashScrapers.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if selectedSection != .stashCommunity, filteredPlugins.isEmpty {
            ContentUnavailableView(
                searchText.isEmpty ? "No Plugins" : "No Matching Plugins",
                systemImage: "puzzlepiece.extension",
                description: Text(
                    searchText.isEmpty
                        ? "Refresh the community catalog or change visibility settings."
                        : "Try a different search or capability filter."))
        }
    }

    private var visibleSections: [AdministrativePluginsSection] {
        hidesNsfw ? [.installed, .prismediaCommunity] : AdministrativePluginsSection.allCases
    }

    private var visiblePlugins: [AdministrativePlugin] {
        AdministrativePluginVisibilityPolicy.visiblePlugins(plugins, hidesNsfw: hidesNsfw)
    }

    private var filteredPlugins: [AdministrativePlugin] {
        let sectionItems =
            selectedSection == .installed
            ? visiblePlugins.filter(\.installed)
            : visiblePlugins.filter { !$0.id.hasPrefix("stash-") }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return sectionItems.filter { plugin in
            let matchesSearch =
                query.isEmpty || plugin.name.lowercased().contains(query) || plugin.id.lowercased().contains(query)
            let matchesCapability =
                capabilityFilter == "all" || plugin.supports.contains { $0.entityKind == capabilityFilter }
            return matchesSearch && matchesCapability
        }
    }

    private var filteredStashScrapers: [AdministrativeStashScraper] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return stashScrapers }
        return stashScrapers.filter {
            $0.name.lowercased().contains(query) || $0.providerID.lowercased().contains(query)
        }
    }

    private var capabilityKinds: [String] {
        Set(visiblePlugins.flatMap(\.supports).map(\.entityKind)).sorted()
    }

    private var installedPluginIDs: Set<String> {
        Set(plugins.filter(\.installed).map(\.id))
    }

    private func refreshSelected() async {
        if selectedSection == .stashCommunity { await loadStash() } else { await loadCatalog() }
    }

    private func loadCatalog() async {
        isLoading = true
        defer { isLoading = false }
        do { plugins = try await service.catalog() } catch { errorMessage = error.localizedDescription }
    }

    private func loadStash() async {
        guard !hidesNsfw else {
            selectedSection = .installed
            return
        }
        isRefreshingStash = true
        defer { isRefreshingStash = false }
        do { stashScrapers = try await service.stashCatalog() } catch { errorMessage = error.localizedDescription }
    }

    private func install(_ id: String) async {
        do {
            _ = try await PluginAdministrationUseCase(service: service).install(id: id)
            await loadCatalog()
        } catch { errorMessage = error.localizedDescription }
    }

    private func installStash(_ scraper: AdministrativeStashScraper) async {
        guard !hidesNsfw else { return }
        installingStashID = scraper.providerID
        defer { installingStashID = nil }
        await install(scraper.providerID)
    }
}

#if DEBUG
    #Preview("Plugins · Regular") {
        AdministrativePluginsView(service: Step4AdministrationPreviewService(), hidesNsfw: false)
            .frame(width: 1_100, height: 720)
    }

    #Preview("Plugins · NSFW Hidden") {
        AdministrativePluginsView(service: Step4AdministrationPreviewService(), hidesNsfw: true)
    }

    #Preview("Plugins · Accessibility") {
        AdministrativePluginsView(service: Step4AdministrationPreviewService(), hidesNsfw: false)
            .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
