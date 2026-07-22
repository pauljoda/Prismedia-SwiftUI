import SwiftUI

public struct EntityGridView<TopContent: View, ItemContent: View>: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(\.prismediaPageIsActive) private var pageIsActive
    @Environment(\.scenePhase) private var scenePhase
    @State private var snapshot: EntityGridSnapshot
    @State private var searchText = ""
    @State private var filtersPresented = false
    @State private var displayMode: EntityGridDisplayMode
    @State private var density: EntityGridDensity
    @State private var pageSize: Int
    @State private var presets: [EntityGridPreset]
    @State private var presetName = ""
    @State private var savePresetPresented = false
    @State private var selection = EntityGridSelectionState()
    @State private var actionInFlight: EntityGridSelectionAction?
    @State private var actionConfirmation: EntityGridActionConfirmation?
    @State private var mutationFailures: [EntityGridMutationFailure] = []
    @State private var mutationFailureAlertPresented = false
    #if os(iOS) || os(macOS)
        @State private var collectionSheetPresented = false
        @State private var collectionSheetReferences: [CollectionEntityReference] = []
    #endif
    #if os(tvOS)
        @Environment(TVTabFocusCoordinator.self) private var tabFocusCoordinator
        @State private var lastFocusedItemID: UUID?
        @State private var tvCollectionOptions: [EntityThumbnail] = []
        @State private var tvCollectionOptionsAreLoading = false
        @State private var tvCollectionOptionsLoadFailed = false
        @FocusState private var tvGridFocus: TVGridFocus?
    #endif

    private let configuration: EntityGridConfiguration
    private let presentation: EntityGridPresentation
    private let service: EntityGridService
    private let controlCatalog: EntityGridControlCatalog
    private let preferencesStore: EntityGridPreferencesStore
    private let horizontalContentPadding: CGFloat
    private let feedMediaDependencies: EntityMediaFeedDependencies?
    private let onOpenFeedItem: ((EntityThumbnail, EntityMediaSequence) -> Void)?
    private let automaticRefreshInterval: Duration?
    private let actionPolicy: EntityGridActionPolicy
    private let mutationService: (any EntityGridMutationServicing)?
    private let prefersInitialTVFocus: Bool
    private let topContent: (EntityGridTopContentContext) -> TopContent
    private let itemContent: (EntityThumbnail, EntityThumbnailLayout) -> ItemContent

    public init(
        configuration: EntityGridConfiguration,
        loader: any EntityGridLoading,
        presentation: EntityGridPresentation = .screen,
        preferencesStore: EntityGridPreferencesStore = .standard,
        horizontalContentPadding: CGFloat? = nil,
        feedMediaDependencies: EntityMediaFeedDependencies? = nil,
        onOpenFeedItem: ((EntityThumbnail, EntityMediaSequence) -> Void)? = nil,
        automaticRefreshInterval: Duration? = nil,
        startsInSelectionMode: Bool = false,
        actionPolicy: EntityGridActionPolicy = .disabled,
        mutationService: (any EntityGridMutationServicing)? = nil,
        prefersInitialTVFocus: Bool = false,
        @ViewBuilder topContent: @escaping (EntityGridTopContentContext) -> TopContent,
        @ViewBuilder itemContent: @escaping (EntityThumbnail, EntityThumbnailLayout) -> ItemContent
    ) {
        self.configuration = configuration
        self.presentation = presentation
        service = EntityGridService(loader: loader)
        controlCatalog = EntityGridControlCatalog(query: configuration.query)
        self.preferencesStore = preferencesStore
        self.horizontalContentPadding =
            horizontalContentPadding
            ?? (presentation == .screen ? PrismediaSpacing.extraLarge : 0)
        self.feedMediaDependencies = feedMediaDependencies
        self.onOpenFeedItem = onOpenFeedItem
        self.automaticRefreshInterval = automaticRefreshInterval
        self.actionPolicy = actionPolicy
        self.mutationService = mutationService
        self.prefersInitialTVFocus = prefersInitialTVFocus
        self.topContent = topContent
        self.itemContent = itemContent
        let restoredPreferences = preferencesStore.load(for: configuration.preferencesID)
        let restoredControls = restoredPreferences?.controls(baselineQuery: configuration.query)
        _displayMode = State(
            initialValue: configuration.resolvedDisplayMode(
                restoring: restoredPreferences?.displayMode
            )
        )
        _density = State(initialValue: restoredPreferences?.density ?? .standard)
        _pageSize = State(initialValue: restoredPreferences?.pageSize ?? configuration.pageSize)
        _presets = State(initialValue: preferencesStore.loadPresets(for: configuration.preferencesID))
        _selection = State(
            initialValue: EntityGridSelectionState(
                isActive: startsInSelectionMode && actionPolicy.selectionEnabled
            )
        )
        _snapshot = State(
            initialValue: EntityGridSnapshot(
                configuration: configuration,
                restoredControls: restoredControls
            )
        )
    }

    public var body: some View {
        presentedContent
            #if os(macOS)
                .onExitCommand {
                    if selection.isActive, actionInFlight == nil {
                        exitSelection()
                    }
                }
            #endif
            .sheet(isPresented: $filtersPresented) {
                EntityGridControlsView(
                    controls: snapshot.controls,
                    catalog: controlCatalog,
                    defaultFilters: configuration.defaultFilters
                ) { controls in
                    Task { await applyControls(controls) }
                }
            }
            .alert("Save Grid Preset", isPresented: $savePresetPresented) {
                TextField("Preset name", text: $presetName)
                Button("Cancel", role: .cancel) { presetName = "" }
                Button("Save") { savePreset() }
                    .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Save the current sort, filters, layout, density, and page size.")
            }
            .confirmationDialog(
                actionConfirmation?.title ?? "Confirm Action",
                isPresented: actionConfirmationPresented,
                titleVisibility: .visible
            ) {
                if let confirmation = actionConfirmation {
                    Button(
                        confirmation.isDestructive ? "Continue" : "Apply",
                        role: confirmation.isDestructive ? .destructive : nil
                    ) {
                        Task { await perform(confirmation.action) }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text(actionConfirmation?.message ?? "")
            }
            .alert("Some Items Couldn’t Be Updated", isPresented: mutationFailurePresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(mutationFailureMessage)
            }
            #if os(iOS) || os(macOS)
                .sheet(isPresented: $collectionSheetPresented) {
                    AddToCollectionSheet(items: collectionSheetReferences) { result in
                        receiveMutationResult(result)
                    }
                }
            #endif
            .task(id: searchText) {
                guard configuration.supportsSearch else { return }
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                await searchIfChanged()
            }
            .onChange(of: searchText) { _, newValue in
                guard
                    configuration.supportsSearch,
                    newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    snapshot.activeSearch != nil
                else { return }

                Task { await submitSearch() }
            }
            .task {
                await loadIfNeeded()
            }
            .task(id: automaticRefreshIsActive) {
                guard automaticRefreshIsActive, let automaticRefreshInterval else { return }
                while automaticRefreshIsActive {
                    do { try await Task.sleep(for: automaticRefreshInterval) } catch { return }
                    guard !Task.isCancelled, automaticRefreshIsActive else { return }
                    await refresh()
                }
            }
            #if os(tvOS)
                .task {
                    await loadTVCollectionOptionsIfNeeded()
                }
                .defaultFocus($tvGridFocus, defaultTVGridFocus)
                .onChange(of: tvGridFocus) { _, focus in
                    guard case .item(let itemID) = focus else { return }
                    lastFocusedItemID = itemID
                }
                .onAppear(perform: restoreTVGridFocusIfNeeded)
                .onChange(of: snapshot.items.map(\.id)) {
                    restoreTVGridFocusIfNeeded()
                }
            #endif
            .onChange(of: environment.entityListRevision) { _, _ in
                Task { await refresh() }
            }
            .accessibilityIdentifier(
                presentation == .screen ? "entity.grid" : "entity.grid.embedded"
            )
    }

    @ViewBuilder
    private var presentedContent: some View {
        switch presentation {
        case .screen:
            screenContent
        case .embedded:
            embeddedContent
        }
    }

    private var automaticRefreshIsActive: Bool {
        automaticRefreshInterval != nil && pageIsActive && scenePhase == .active
    }

    private var screenContent: some View {
        Group {
            switch snapshot.state {
            case .idle, .loading:
                PrismediaLoadingView("Loading \(configuration.title.lowercased())…")

            case .content, .empty, .failed:
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                        #if os(tvOS)
                            TVEntityGridHeader(
                                title: configuration.title,
                                focus: $tvGridFocus,
                                onMove: moveFromTVGridHeader,
                                sortMenu: { sortMenu },
                                filterButton: { filterButton },
                                displayMenu: { displayMenu }
                            )
                                .padding(.horizontal, horizontalContentPadding)
                        #endif

                        if let errorMessage = snapshot.errorMessage {
                            errorBanner(errorMessage)
                                .padding(.horizontal, horizontalContentPadding)
                        }

                        if !mutationFailures.isEmpty {
                            EntityGridMutationFailureBanner(failures: mutationFailures)
                                .padding(.horizontal, horizontalContentPadding)
                        }

                        stateContent
                    }
                    .padding(.vertical, PrismediaSpacing.extraLarge)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .refreshable {
                    await refresh()
                }
                .scrollBounceBehavior(.always, axes: .vertical)
            }
        }
        .prismediaScreenBackground()
        #if os(tvOS)
            .navigationTitle("")
        #else
            .navigationTitle(selection.isActive ? "\(selection.selectedIDs.count) Selected" : configuration.title)
        #endif
        .prismediaInlineNavigationTitle()
        .toolbar {
            #if !os(tvOS)
                if selection.isActive {
                    EntityGridSelectionToolbar(
                        selectedCount: selection.selectedIDs.count,
                        collectionEligibleCount: selectedCollectionReferences.count,
                        availableBuiltInActions: availableBuiltInActions,
                        customActions: availableCustomActions,
                        markNsfwValue: actionPolicy.nsfwMutationValue(for: selectedItems),
                        isProcessing: actionInFlight != nil,
                        onSelectAll: selectAllVisible,
                        onClear: clearSelection,
                        onAction: requestAction
                    )

                    ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)

                    ToolbarItem(placement: trailingToolbarPlacement) {
                        selectionToggleButton
                    }
                } else {
                    if actionPolicy.selectionEnabled {
                        ToolbarItem(placement: trailingToolbarPlacement) {
                            selectionToggleButton
                        }

                        ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)
                    }

                    ToolbarItemGroup(placement: trailingToolbarPlacement) {
                        displayMenu
                        sortMenu
                        filterButton
                    }
                }
            #endif
        }
        .modifier(
            EntityGridSearchModifier(
                isEnabled: configuration.supportsSearch,
                text: $searchText,
                onSubmit: {
                    Task { await submitSearch() }
                }
            )
        )
    }

    private var embeddedContent: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            embeddedHeader
                .padding(.horizontal, horizontalContentPadding)

            if let errorMessage = snapshot.errorMessage {
                errorBanner(errorMessage)
                    .padding(.horizontal, horizontalContentPadding)
            }

            if !mutationFailures.isEmpty {
                EntityGridMutationFailureBanner(failures: mutationFailures)
                    .padding(.horizontal, horizontalContentPadding)
            }

            switch snapshot.state {
            case .idle, .loading:
                ProgressView("Loading \(configuration.title.lowercased())…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PrismediaSpacing.extraExtraLarge)
            case .content, .empty, .failed:
                stateContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var embeddedHeader: some View {
        HStack(alignment: .center, spacing: PrismediaSpacing.medium) {
            Text(configuration.title)
                .font(.title3.bold())
                .foregroundStyle(PrismediaColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(String(snapshot.totalCount))
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)

            Spacer(minLength: PrismediaSpacing.medium)

            #if os(tvOS)
                displayMenu
                    .buttonStyle(.glass)
                sortMenu
                    .buttonStyle(.glass)
                filterButton
                    .buttonStyle(.glass)
                if actionPolicy.selectionEnabled {
                    selectionToggleButton
                        .buttonStyle(.glass)
                }
            #else
                displayMenu
                sortMenu
                filterButton
                if actionPolicy.selectionEnabled {
                    selectionToggleButton
                }
            #endif
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var stateContent: some View {
        if snapshot.state == .content {
            contentGrid
        } else if snapshot.state == .empty {
            ContentUnavailableView {
                Label(configuration.emptyTitle, systemImage: "square.grid.2x2")
            } description: {
                Text(emptyDescription)
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(.horizontal, horizontalContentPadding)
        } else if case .failed(let message) = snapshot.state {
            ContentUnavailableView {
                Label("Couldn’t Load \(configuration.title)", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                PrismediaButton("Try Again", variant: .prominent) {
                    Task { await loadFirstPage(preservingContent: false) }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(.horizontal, horizontalContentPadding)
        }
    }

    private var contentGrid: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            topContent(
                EntityGridTopContentContext(
                    query: snapshot.controls.applying(to: configuration.query),
                    search: snapshot.activeSearch,
                    visibleItemCount: snapshot.items.count
                )
            )
            .padding(.horizontal, horizontalContentPadding)

            if presentation == .screen {
                Text(itemCountLabel)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(PrismediaColor.textMuted)
                    .accessibilityIdentifier("entity.grid.count")
                    .padding(.horizontal, horizontalContentPadding)
            }

            laidOutGridItems

            paginationFooter
                .padding(.horizontal, horizontalContentPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var laidOutGridItems: some View {
        if usesFullBleedMediaFeed {
            gridItems
        } else {
            gridItems
                .padding(.horizontal, horizontalContentPadding)
        }
    }

    @ViewBuilder
    private var gridItems: some View {
        if displayMode == .feed,
            let feedMediaDependencies,
            let onOpenFeedItem
        {
            EntityMediaFeedView(
                items: snapshot.items,
                mediaSequence: snapshot.mediaSequence(
                    configuration: configuration,
                    pageSize: pageSize
                ),
                dependencies: feedMediaDependencies,
                selection: selection,
                onToggleSelection: toggleSelection,
                onOpen: onOpenFeedItem,
                onItemAppear: itemDidAppear
            )
        } else {
            EntityThumbnailGrid(
                items: snapshot.items,
                mediaSequence: snapshot.mediaSequence(
                    configuration: configuration,
                    pageSize: pageSize
                ),
                minimumColumnWidth: configuration.minimumColumnWidth,
                displayMode: displayMode,
                density: density
            ) { item, layout in
                EntityGridSelectionSurface(
                    item: item,
                    isSelectionActive: selection.isActive,
                    isSelected: selection.selectedIDs.contains(item.id),
                    onToggle: { toggleSelection(item.id) },
                    collectionOptions: collectionMenuOptions,
                    collectionOptionsAreLoading: collectionMenuOptionsAreLoading,
                    collectionOptionsLoadFailed: collectionMenuOptionsLoadFailed,
                    onAddToCollection: addToCollectionAction(for: item),
                    onReloadCollectionOptions: reloadCollectionMenuOptions
                ) {
                    itemContent(item, layout)
                }
                #if os(tvOS)
                    .focused($tvGridFocus, equals: .item(item.id))
                #endif
                .onAppear { itemDidAppear(item.id) }
            }
        }
    }

    private var usesFullBleedMediaFeed: Bool {
        displayMode == .feed && feedMediaDependencies != nil && onOpenFeedItem != nil
    }

    private func itemDidAppear(_ itemID: UUID) {
        prewarmArtwork(after: itemID)
        guard itemID == snapshot.items.last?.id else { return }
        Task { await loadNextPage() }
    }

    #if os(tvOS)
        private func moveFromTVGridHeader(_ direction: MoveCommandDirection) {
            switch direction {
            case .down:
                guard let firstID = snapshot.items.first?.id else { return }
                tvGridFocus = .item(firstID)
            case .up:
                tabFocusCoordinator.requestFocus()
            case .left:
                switch tvGridFocus {
                case .display: tvGridFocus = .filter
                case .filter: tvGridFocus = .sort
                default: tvGridFocus = .sort
                }
            case .right:
                switch tvGridFocus {
                case .sort: tvGridFocus = .filter
                case .filter: tvGridFocus = .display
                default: tvGridFocus = .display
                }
            default:
                break
            }
        }
    #endif

    @ViewBuilder
    private var paginationFooter: some View {
        if snapshot.isLoadingNextPage {
            ProgressView("Loading more…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, PrismediaSpacing.large)
        } else if let message = snapshot.paginationErrorMessage {
            VStack(spacing: PrismediaSpacing.medium) {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                PrismediaButton("Try Again") {
                    Task { await loadNextPage() }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PrismediaSpacing.medium)
        }
    }

    private var itemCountLabel: String {
        "\(snapshot.totalCount) item\(snapshot.totalCount == 1 ? "" : "s")"
    }

    @ViewBuilder
    private var selectionToggleButton: some View {
        let button = Button {
            if selection.isActive {
                exitSelection()
            } else {
                selection.enter()
            }
        } label: {
            Image(systemName: selection.isActive ? "checkmark" : "checkmark.circle")
        }
        .disabled(actionInFlight != nil)
        .accessibilityLabel(selection.isActive ? "Done Selecting" : "Select Items")
        .accessibilityIdentifier("entity.grid.selection.toggle")

        #if os(macOS)
            button.keyboardShortcut("s", modifiers: [.command, .shift])
        #else
            button
        #endif
    }

    private var trailingToolbarPlacement: ToolbarItemPlacement {
        #if os(iOS)
            .topBarTrailing
        #else
            .primaryAction
        #endif
    }

    private var sortMenu: some View {
        Menu {
            ForEach(controlCatalog.sortOptions) { option in
                Button {
                    selectSort(option)
                } label: {
                    if snapshot.controls.sort == option {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }

            Divider()

            if snapshot.controls.sort == .random {
                Button {
                    Task { await reshuffle() }
                } label: {
                    Label("Reshuffle", systemImage: "shuffle")
                }
            } else {
                Button {
                    reverseSortDirection()
                } label: {
                    Label(
                        snapshot.controls.sortDescending ? "Descending" : "Ascending",
                        systemImage: snapshot.controls.sortDescending ? "arrow.down" : "arrow.up"
                    )
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort")
        .accessibilityIdentifier("entity.grid.sort")
    }

    private var filterButton: some View {
        Button {
            filtersPresented = true
        } label: {
            Image(
                systemName: snapshot.controls.filters.activeCount > 0
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
            .overlay(alignment: .topTrailing) {
                if snapshot.controls.filters.activeCount > 0 {
                    Text(String(snapshot.controls.filters.activeCount))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(PrismediaColor.onAccent)
                        .padding(PrismediaSpacing.extraSmall)
                        .background(PrismediaColor.accent, in: Circle())
                        .offset(x: 7, y: -7)
                }
            }
        }
        .accessibilityLabel("Filters")
        .accessibilityValue("\(snapshot.controls.filters.activeCount) active")
        .accessibilityIdentifier("entity.grid.filter")
    }

    private var displayMenu: some View {
        Menu {
            if configuration.availableDisplayModes.count > 1 {
                Section("Layout") {
                    ForEach(configuration.availableDisplayModes) { option in
                        Button {
                            selectDisplayMode(option)
                        } label: {
                            Label(
                                option.label,
                                systemImage: displayMode == option ? "checkmark" : option.systemImage
                            )
                        }
                    }
                }
            }

            if displayMode != .list {
                Section("Item Size") {
                    ForEach(EntityGridDensity.allCases) { option in
                        Button {
                            selectDensity(option)
                        } label: {
                            if density == option {
                                Label(option.label, systemImage: "checkmark")
                            } else {
                                Text(option.label)
                            }
                        }
                    }
                }
            }

            Section("Page Size") {
                ForEach(Self.pageSizeOptions, id: \.self) { option in
                    Button {
                        selectPageSize(option)
                    } label: {
                        if pageSize == option {
                            Label("\(option) items", systemImage: "checkmark")
                        } else {
                            Text("\(option) items")
                        }
                    }
                }
            }

            #if !os(tvOS)
                Section("Presets") {
                    ForEach(presets) { preset in
                        Button(preset.name) {
                            Task { await applyPreset(preset) }
                        }
                    }

                    Button {
                        presetName = ""
                        savePresetPresented = true
                    } label: {
                        Label("Save Current as Preset", systemImage: "plus")
                    }

                    if !presets.isEmpty {
                        Menu("Delete Preset", systemImage: "trash") {
                            ForEach(presets) { preset in
                                Button(preset.name, role: .destructive) {
                                    deletePreset(preset)
                                }
                            }
                        }
                    }
                }
            #endif

            Divider()

            Button {
                Task { await resetPreferences() }
            } label: {
                Label("Reset Grid Settings", systemImage: "arrow.counterclockwise")
            }
            .disabled(preferencesAreDefault)
        } label: {
            Image(systemName: displayMode.systemImage)
        }
        .accessibilityLabel("Display options")
        .accessibilityValue("\(displayMode.label), \(density.label) size")
        .accessibilityIdentifier("entity.grid.display")
    }

    private func selectSort(_ sort: EntityGridSort) {
        var controls = snapshot.controls
        controls.sort = sort
        if sort == .random {
            controls.randomSeed = EntityGridControls.nextRandomSeed()
        }
        Task { await applyControls(controls) }
    }

    private func reverseSortDirection() {
        var controls = snapshot.controls
        controls.sortDescending.toggle()
        Task { await applyControls(controls) }
    }

    private func selectDisplayMode(_ mode: EntityGridDisplayMode) {
        guard configuration.availableDisplayModes.contains(mode), displayMode != mode else { return }
        displayMode = mode
        savePreferences()
    }

    private func selectDensity(_ newDensity: EntityGridDensity) {
        guard density != newDensity else { return }
        density = newDensity
        savePreferences()
    }

    private func selectPageSize(_ newPageSize: Int) {
        guard pageSize != newPageSize else { return }
        pageSize = newPageSize
        savePreferences()
        Task { await loadFirstPage(preservingContent: false) }
    }

    private func applyPreset(_ preset: EntityGridPreset) async {
        let preferences = preset.preferences
        snapshot.setControls(preferences.controls(baselineQuery: configuration.query))
        displayMode = configuration.resolvedDisplayMode(restoring: preferences.displayMode)
        density = preferences.density
        pageSize = preferences.pageSize ?? configuration.pageSize
        savePreferences()
        await loadFirstPage(preservingContent: false)
    }

    private func savePreset() {
        preferencesStore.savePreset(
            named: presetName,
            preferences: currentPreferences,
            for: configuration.preferencesID
        )
        presetName = ""
        presets = preferencesStore.loadPresets(for: configuration.preferencesID)
    }

    private func deletePreset(_ preset: EntityGridPreset) {
        preferencesStore.deletePreset(id: preset.id, for: configuration.preferencesID)
        presets = preferencesStore.loadPresets(for: configuration.preferencesID)
    }

    private var emptyDescription: String {
        guard let activeSearch = snapshot.activeSearch else {
            return configuration.emptyDescription
        }
        return "No items match “\(activeSearch)”."
    }

    private func loadIfNeeded() async {
        guard snapshot.state == .idle else { return }
        await loadFirstPage(preservingContent: false)
    }

    private func refresh() async {
        let clock = ContinuousClock()
        let startedAt = clock.now
        let wasRandom = snapshot.controls.sort == .random
        let request = snapshot.beginRefresh(
            configuration: configuration,
            pageSize: pageSize
        )
        if wasRandom { savePreferences() }
        await loadFirstPage(request)

        let elapsed = startedAt.duration(to: clock.now)
        guard let remaining = EntityGridRefreshIndicatorPolicy.remainingDuration(after: elapsed)
        else { return }
        try? await Task.sleep(for: remaining)
    }

    private func submitSearch() async {
        snapshot.setSearch(searchText)
        await loadFirstPage(preservingContent: false)
    }

    private func searchIfChanged() async {
        guard snapshot.setSearch(searchText) else { return }
        await loadFirstPage(preservingContent: false)
    }

    private func applyControls(_ controls: EntityGridControls) async {
        snapshot.setControls(controls)
        savePreferences()
        await loadFirstPage(preservingContent: false)
    }

    private func resetPreferences() async {
        snapshot.resetControls(for: configuration)
        displayMode = configuration.defaultDisplayMode
        density = .standard
        pageSize = configuration.pageSize
        preferencesStore.reset(for: configuration.preferencesID)
        await loadFirstPage(preservingContent: false)
    }

    private func savePreferences() {
        preferencesStore.save(currentPreferences, for: configuration.preferencesID)
    }

    private var currentPreferences: EntityGridPreferences {
        EntityGridPreferences(
            controls: snapshot.controls,
            displayMode: displayMode,
            density: density,
            pageSize: pageSize
        )
    }

    private var preferencesAreDefault: Bool {
        currentPreferences
            == EntityGridPreferences(
                controls: configuration.defaultControls(),
                displayMode: configuration.defaultDisplayMode,
                pageSize: configuration.pageSize
            )
    }

    private func reshuffle() async {
        guard snapshot.reshuffle() else { return }
        savePreferences()
        await loadFirstPage(preservingContent: false)
    }

    private func loadFirstPage(preservingContent: Bool) async {
        let request = snapshot.beginFirstPage(
            configuration: configuration,
            pageSize: pageSize,
            preservingContent: preservingContent
        )

        await loadFirstPage(request)
    }

    private func loadFirstPage(_ request: EntityGridPageRequest) async {
        do {
            let page = try await service.loadFirstPage(request)
            guard !Task.isCancelled else {
                snapshot.cancel(request)
                return
            }
            if snapshot.receiveFirstPage(page, for: request) {
                selection.reconcile(withAvailableIDs: Set(snapshot.items.map(\.id)))
            }
        } catch is CancellationError {
            snapshot.cancel(request)
        } catch {
            guard !Task.isCancelled else {
                snapshot.cancel(request)
                return
            }
            snapshot.failFirstPage(title: configuration.title, for: request)
        }
    }

    private func loadNextPage() async {
        guard
            let request = snapshot.beginNextPage(
                configuration: configuration,
                pageSize: pageSize
            )
        else { return }

        do {
            let page = try await service.loadNextVisiblePage(request)
            guard !Task.isCancelled else {
                snapshot.cancel(request)
                return
            }
            snapshot.receiveNextPage(page, for: request)
        } catch is CancellationError {
            snapshot.cancel(request)
        } catch {
            guard !Task.isCancelled else {
                snapshot.cancel(request)
                return
            }
            snapshot.failNextPage(for: request)
        }
    }

    private func prewarmArtwork(after itemID: UUID) {
        guard let client = environment.client else { return }
        let urls =
            EntityGridArtworkPrewarming
            .paths(after: itemID, in: snapshot.items)
            .compactMap { client.assetURL(for: $0) }
        guard !urls.isEmpty else { return }

        Task(priority: .utility) {
            await RemoteArtworkPipeline.shared.prewarm(urls)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: PrismediaSpacing.medium) {
            Text(message)
                .font(.callout)
                .foregroundStyle(PrismediaColor.destructive)

            Spacer(minLength: 8)

            PrismediaButton("Try Again") {
                Task { await refresh() }
            }
        }
        .padding(PrismediaSpacing.extraLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
    }

    private var selectedItems: [EntityThumbnail] {
        snapshot.items.filter { selection.selectedIDs.contains($0.id) }
    }

    private var selectedCollectionReferences: [CollectionEntityReference] {
        actionPolicy.collectionReferences(in: selectedItems)
    }

    private var availableBuiltInActions: Set<EntityGridBuiltInAction> {
        guard mutationService != nil else { return [] }
        return actionPolicy.availableBuiltInActions(for: selectedItems)
    }

    private var availableCustomActions: [EntityGridCustomAction] {
        actionPolicy.availableCustomActions(for: selectedItems)
    }

    private var actionConfirmationPresented: Binding<Bool> {
        Binding(
            get: { actionConfirmation != nil },
            set: { if !$0 { actionConfirmation = nil } }
        )
    }

    private var mutationFailurePresented: Binding<Bool> {
        Binding(
            get: { mutationFailureAlertPresented },
            set: { mutationFailureAlertPresented = $0 }
        )
    }

    private var mutationFailureMessage: String {
        let count = mutationFailures.count
        let details = mutationFailures.prefix(4)
            .map { "\($0.title): \($0.message)" }
            .joined(separator: "\n")
        let summary = selection.isActive
            ? "remain selected so you can retry"
            : "could not be updated"
        return "\(count) item\(count == 1 ? "" : "s") \(summary).\n\(details)"
    }

    private func toggleSelection(_ entityID: UUID) {
        selection.toggle(entityID)
    }

    private func selectAllVisible() {
        selection.selectAllVisible(snapshot.items.map(\.id))
    }

    private func clearSelection() {
        selection.clear()
        mutationFailures.removeAll()
    }

    private func exitSelection() {
        selection.exit()
        mutationFailures.removeAll()
    }

    private func requestAction(_ action: EntityGridSelectionAction) {
        guard actionInFlight == nil, !selectedItems.isEmpty else { return }
        switch action {
        case .addToCollection:
            #if os(iOS) || os(macOS)
                presentCollectionSheet(with: selectedCollectionReferences)
            #endif
        case .markNsfw(let value):
            actionConfirmation = EntityGridActionConfirmation(
                action: action,
                title: value ? "Mark Selected Items NSFW?" : "Mark Selected Items SFW?",
                message:
                    "This updates the safety classification for \(selectedItems.count) selected item\(selectedItems.count == 1 ? "" : "s").",
                isDestructive: false
            )
        case .removeWanted:
            actionConfirmation = EntityGridActionConfirmation(
                action: action,
                title: "Remove Selected Wanted Items?",
                message:
                    "This stops acquisition work, removes fileless placeholders, and keeps them out of automatic discovery until they are explicitly requested again.",
                isDestructive: true
            )
        case .custom(let id):
            guard let custom = actionPolicy.customActions.first(where: { $0.id == id }) else { return }
            if let title = custom.confirmationTitle {
                actionConfirmation = EntityGridActionConfirmation(
                    action: action,
                    title: title,
                    message: custom.confirmationMessage ?? "Apply this action to the selected items?",
                    isDestructive: custom.isDestructive
                )
            } else {
                Task { await perform(action) }
            }
        }
    }

    private func perform(_ action: EntityGridSelectionAction) async {
        guard actionInFlight == nil else { return }
        let targets = selectedItems
        guard !targets.isEmpty else { return }
        actionConfirmation = nil
        actionInFlight = action
        let result: EntityGridMutationResult
        switch action {
        case .addToCollection:
            actionInFlight = nil
            return
        case .markNsfw(let value):
            result = await actionService?.markNsfw(value, items: targets) ?? unavailableResult(targets)
        case .removeWanted:
            result = await actionService?.removeWanted(items: targets) ?? unavailableResult(targets)
        case .custom(let id):
            guard let custom = actionPolicy.customActions.first(where: { $0.id == id }) else {
                actionInFlight = nil
                return
            }
            result = await custom.perform(with: targets)
        }
        actionInFlight = nil
        receiveMutationResult(result)
    }

    private var actionService: EntityGridActionService? {
        mutationService.map(EntityGridActionService.init(mutations:))
    }

    private func receiveMutationResult(_ result: EntityGridMutationResult) {
        selection.remove(result.succeededIDs)
        mutationFailures = result.failures
        mutationFailureAlertPresented = !result.failures.isEmpty
        if !result.succeededIDs.isEmpty {
            environment.entityDidMutate()
        }
    }

    private func addToCollectionAction(
        for item: EntityThumbnail
    ) -> ((EntityThumbnail) -> Void)? {
        guard
            mutationService != nil,
            !actionPolicy.collectionReferences(in: [item]).isEmpty
        else { return nil }

        return { collection in
            #if os(tvOS)
                Task {
                    await add(item, to: collection)
                }
            #else
                presentCollectionSheet(
                    with: actionPolicy.collectionReferences(in: [item])
                )
            #endif
        }
    }

    #if os(iOS) || os(macOS)
    private func presentCollectionSheet(with references: [CollectionEntityReference]) {
        guard !references.isEmpty else { return }
        collectionSheetReferences = references
        collectionSheetPresented = true
    }
    #endif

    private var collectionMenuOptions: [EntityThumbnail] {
        #if os(tvOS)
            tvCollectionOptions
        #else
            []
        #endif
    }

    private var collectionMenuOptionsAreLoading: Bool {
        #if os(tvOS)
            tvCollectionOptionsAreLoading
        #else
            false
        #endif
    }

    private var collectionMenuOptionsLoadFailed: Bool {
        #if os(tvOS)
            tvCollectionOptionsLoadFailed
        #else
            false
        #endif
    }

    private var reloadCollectionMenuOptions: (() -> Void)? {
        #if os(tvOS)
            reloadTVCollectionOptions
        #else
            nil
        #endif
    }

    #if os(tvOS)
        private var defaultTVGridFocus: TVGridFocus? {
            guard prefersInitialTVFocus else { return nil }
            if let lastFocusedItemID,
                snapshot.items.contains(where: { $0.id == lastFocusedItemID })
            {
                return .item(lastFocusedItemID)
            }
            return snapshot.items.first.map { .item($0.id) }
        }

        private func restoreTVGridFocusIfNeeded() {
            guard let target = defaultTVGridFocus else { return }
            Task { @MainActor in
                await Task.yield()
                tvGridFocus = target
            }
        }

        private func loadTVCollectionOptionsIfNeeded() async {
            guard tvCollectionOptions.isEmpty, !tvCollectionOptionsAreLoading else { return }
            await loadTVCollectionOptions()
        }

        private func reloadTVCollectionOptions() {
            Task { await loadTVCollectionOptions() }
        }

        private func loadTVCollectionOptions() async {
            guard let mutationService else { return }
            tvCollectionOptionsAreLoading = true
            tvCollectionOptionsLoadFailed = false
            defer { tvCollectionOptionsAreLoading = false }
            do {
                tvCollectionOptions = try await mutationService.loadCollectionOptions().sorted {
                    $0.title.localizedStandardCompare($1.title) == .orderedAscending
                }
            } catch is CancellationError {
                return
            } catch {
                tvCollectionOptionsLoadFailed = true
            }
        }

        private func add(
            _ item: EntityThumbnail,
            to collection: EntityThumbnail
        ) async {
            let result = await actionService?.addToCollection(
                collection.id,
                items: [item]
            ) ?? unavailableResult([item])
            receiveMutationResult(result)
        }
    #endif

    private func unavailableResult(
        _ items: [EntityThumbnail]
    ) -> EntityGridMutationResult {
        EntityGridMutationResult(
            failures: items.map {
                EntityGridMutationFailure(
                    entityID: $0.id,
                    title: $0.title,
                    message: "The server mutation service is unavailable."
                )
            }
        )
    }

    private static var pageSizeOptions: [Int] { [24, 48, 96] }
}

/// The shared, presentational entity grid used by both library pages and
/// child collections embedded in an entity detail page.

extension EntityGridView where TopContent == EmptyView {
    public init(
        configuration: EntityGridConfiguration,
        loader: any EntityGridLoading,
        presentation: EntityGridPresentation = .screen,
        preferencesStore: EntityGridPreferencesStore = .standard,
        horizontalContentPadding: CGFloat? = nil,
        feedMediaDependencies: EntityMediaFeedDependencies? = nil,
        onOpenFeedItem: ((EntityThumbnail, EntityMediaSequence) -> Void)? = nil,
        automaticRefreshInterval: Duration? = nil,
        startsInSelectionMode: Bool = false,
        actionPolicy: EntityGridActionPolicy = .disabled,
        mutationService: (any EntityGridMutationServicing)? = nil,
        prefersInitialTVFocus: Bool = false,
        @ViewBuilder itemContent: @escaping (EntityThumbnail, EntityThumbnailLayout) -> ItemContent
    ) {
        self.init(
            configuration: configuration,
            loader: loader,
            presentation: presentation,
            preferencesStore: preferencesStore,
            horizontalContentPadding: horizontalContentPadding,
            feedMediaDependencies: feedMediaDependencies,
            onOpenFeedItem: onOpenFeedItem,
            automaticRefreshInterval: automaticRefreshInterval,
            startsInSelectionMode: startsInSelectionMode,
            actionPolicy: actionPolicy,
            mutationService: mutationService,
            prefersInitialTVFocus: prefersInitialTVFocus,
            topContent: { _ in EmptyView() },
            itemContent: itemContent
        )
    }
}

extension EntityGridView where TopContent == EmptyView, ItemContent == EntityThumbnailCardView {
    public init(
        configuration: EntityGridConfiguration,
        loader: any EntityGridLoading,
        preferencesStore: EntityGridPreferencesStore = .standard,
        automaticRefreshInterval: Duration? = nil,
        startsInSelectionMode: Bool = false,
        actionPolicy: EntityGridActionPolicy = .disabled,
        mutationService: (any EntityGridMutationServicing)? = nil
    ) {
        self.init(
            configuration: configuration,
            loader: loader,
            preferencesStore: preferencesStore,
            automaticRefreshInterval: automaticRefreshInterval,
            startsInSelectionMode: startsInSelectionMode,
            actionPolicy: actionPolicy,
            mutationService: mutationService
        ) { item, layout in
            EntityThumbnailCardView(item: item, layout: layout)
        }
    }
}

#if DEBUG

    #Preview("Entity Grid · Content") {
        PreviewShell(signedIn: true) {
            NavigationStack {
                EntityGridView(
                    configuration: EntityGridConfiguration(
                        title: "Videos",
                        query: EntityListQuery(kind: .video),
                        supportsSearch: true
                    ),
                    loader: EntityGridPreviewLoader(
                        response: EntityListResponse(items: PrismediaPreviewData.videos)
                    ),
                    preferencesStore: .disabled
                )
            }
        }
        #if os(tvOS)
            .environment(TVTabFocusCoordinator())
        #endif
    }
#endif
