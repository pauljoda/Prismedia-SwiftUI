import SwiftUI

struct AdministrativePluginsView: View {
    @State private var catalog = AdministrativeCollectionLoadState<AdministrativePlugin>()
    @State private var stashCatalog = AdministrativeCollectionLoadState<AdministrativeStashScraper>()
    @State private var selectedSection: AdministrativePluginsSection? = .installed
    @State private var selectedPlugin: AdministrativePlugin?
    @State private var searchText = ""
    @State private var capabilityFilter = "all"
    @State private var installingStashID: String?
    @State private var errorMessage: String?
    private let service: any PluginAdministrationServicing
    private let hidesNsfw: Bool

    init(service: any PluginAdministrationServicing, hidesNsfw: Bool) {
        self.service = service
        self.hidesNsfw = hidesNsfw
    }

    var body: some View {
        platformContent
            .prismediaScreenBackground()
            .task { await loadCatalog() }
            .task(id: selectedSection) {
                if selectedSection == .stashCommunity, stashScrapers.isEmpty { await loadStash() }
            }
            .onChange(of: selectedSection) {
                searchText = ""
                capabilityFilter = "all"
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
    private var platformContent: some View {
        #if os(macOS)
            NavigationStack {
                List {
                    Section {
                        Picker("Plugin Source", selection: $selectedSection) {
                            ForEach(visibleSections) { section in
                                Label(section.label, systemImage: section.systemImage)
                                    .tag(Optional(section))
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.clear)

                    catalogFailure

                    if selectedSection == .stashCommunity {
                        stashContent
                    } else {
                        pluginContent
                    }
                }
                .listStyle(.inset)
                .navigationTitle(selectedSection?.label ?? "Plugins")
                .searchable(text: $searchText, prompt: "Search plugins")
                .toolbar { pluginToolbar }
                .overlay { emptyOrLoadingOverlay }
                .refreshable {
                    await PrismediaRefreshAction.perform { await refreshSelected() }
                }
            }
        #else
            NavigationSplitView {
                List(visibleSections, selection: $selectedSection) { section in
                    NavigationLink(value: section) {
                        Label {
                            Text(section.label)
                        } icon: {
                            Image(systemName: section.systemImage)
                                .foregroundStyle(sectionAccent(for: section))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                }
                .prismediaScreenBackground()
                .navigationTitle("Plugins")
            } detail: {
                List {
                    catalogFailure
                    if selectedSection == .stashCommunity {
                        stashContent
                    } else {
                        pluginContent
                    }
                }
                .prismediaScreenBackground()
                .navigationTitle(selectedSection?.label ?? "Plugins")
                .searchable(text: $searchText, prompt: "Search plugins")
                .toolbar {
                    pluginToolbar
                }
                .overlay { emptyOrLoadingOverlay }
                .refreshable {
                    await PrismediaRefreshAction.perform {
                        await refreshSelected()
                    }
                }
            }
        #endif
    }

    @ToolbarContentBuilder
    private var pluginToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if selectedSection != .stashCommunity {
                Menu("Filter Capabilities", systemImage: "line.3.horizontal.decrease.circle") {
                    Picker("Content Type", selection: $capabilityFilter) {
                        Text("All Content Types").tag("all")
                        ForEach(capabilityKinds, id: \.self) { kind in
                            Text(EntityKind(rawValue: kind).displayLabel).tag(kind)
                        }
                    }
                }
                .prismediaToolbarActionLabelStyle()
            }

            Button("Refresh", systemImage: "arrow.clockwise") {
                Task { await refreshSelected() }
            }
            .prismediaToolbarActionLabelStyle()
            .disabled(selectedCatalogIsLoading)
        }
    }

    @ViewBuilder
    private var pluginContent: some View {
        ForEach(filteredPlugins) { plugin in
            Button {
                selectedPlugin = plugin
            } label: {
                AdministrativePluginCatalogRow(plugin: plugin)
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
        if selectedCatalogIsLoading, selectedCatalogIsEmpty {
            PrismediaLoadingView("Loading plugins…")
        } else if selectedCatalogError != nil {
            EmptyView()
        } else if selectedSection == .stashCommunity ? filteredStashScrapers.isEmpty : filteredPlugins.isEmpty {
            ContentUnavailableView {
                Label(hasActiveFilters ? "No Matching Plugins" : "No Plugins", systemImage: "puzzlepiece.extension")
            } description: {
                Text(
                    hasActiveFilters
                        ? "Try a different search or content type." : "No plugins are available in this source.")
            } actions: {
                if hasActiveFilters {
                    Button("Clear Filters", systemImage: "line.3.horizontal.decrease.circle") {
                        searchText = ""
                        capabilityFilter = "all"
                    }
                } else if selectedSection == .installed {
                    Button("Browse Community", systemImage: "puzzlepiece.extension") {
                        selectedSection = .prismediaCommunity
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var catalogFailure: some View {
        if let message = selectedCatalogError {
            Section {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Label(
                        selectedCatalogIsEmpty ? "Couldn't Load Plugins" : "Couldn't Refresh Plugins",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.headline)
                    Text(message).font(.subheadline).foregroundStyle(.secondary)
                }
                Button("Retry", systemImage: "arrow.clockwise") { Task { await refreshSelected() } }
                    .disabled(selectedCatalogIsLoading)
            }
        }
    }

    private var plugins: [AdministrativePlugin] { catalog.items }
    private var stashScrapers: [AdministrativeStashScraper] { stashCatalog.items }
    private var selectedCatalogIsLoading: Bool {
        selectedSection == .stashCommunity ? stashCatalog.isLoading : catalog.isLoading
    }
    private var selectedCatalogIsEmpty: Bool {
        selectedSection == .stashCommunity ? stashScrapers.isEmpty : plugins.isEmpty
    }
    private var selectedCatalogError: String? {
        selectedSection == .stashCommunity ? stashCatalog.errorMessage : catalog.errorMessage
    }
    private var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || capabilityFilter != "all"
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

    private func sectionAccent(for section: AdministrativePluginsSection) -> Color {
        let index = visibleSections.firstIndex(of: section) ?? 0
        return PrismediaColor.materialSpectrumColor(at: index)
    }

    private func refreshSelected() async {
        if selectedSection == .stashCommunity { await loadStash() } else { await loadCatalog() }
    }

    private func loadCatalog() async {
        let request = catalog.begin()
        do {
            let items = try await service.catalog()
            catalog.succeed(items, request: request, isCancelled: Task.isCancelled)
        } catch {
            catalog.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    private func loadStash() async {
        guard !hidesNsfw else {
            selectedSection = .installed
            return
        }
        let request = stashCatalog.begin()
        do {
            let items = try await service.stashCatalog()
            stashCatalog.succeed(items, request: request, isCancelled: Task.isCancelled)
        } catch {
            stashCatalog.fail(error, request: request, isCancelled: Task.isCancelled)
        }
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
