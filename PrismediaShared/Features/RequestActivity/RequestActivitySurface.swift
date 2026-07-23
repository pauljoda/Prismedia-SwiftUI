import SwiftUI

#if os(iOS) || os(macOS)
    public struct RequestActivitySurface: View {
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        #if os(iOS)
            @Environment(\.editMode) private var editMode
        #endif

        @State private var downloads: [RequestActivityDownload] = []
        @State private var wantedPage: RequestActivityWantedPage?
        @State private var history: [RequestActivityHistoryEntry] = []
        @State private var isLoading = true
        @State private var isActing = false
        @State private var errorMessage: String?
        @State private var query = ""
        @State private var selectedStatus = RequestActivityStatusFilter.all
        @State private var selectedDownloadKind: EntityKind?
        @State private var selectedWantedKind: EntityKind?
        @State private var sort = RequestActivitySort.updatedNewest
        @State private var page = 1
        @State private var selectedIDs = Set<UUID>()
        @State private var pendingRemovalIDs = Set<UUID>()
        @State private var selectedAcquisition: RequestActivityDownload?

        private let section: RequestActivitySection
        private let service: any RequestActivityServicing
        private let referenceDate: Date
        private let resolveAssetURL: (String) -> URL?
        private let onOpenEntity: ((UUID, EntityKind) -> Void)?
        private let onChooseRelease: ((UUID) -> Void)?

        public init(
            section: RequestActivitySection,
            service: any RequestActivityServicing,
            referenceDate: Date = .now,
            resolveAssetURL: @escaping (String) -> URL? = { URL(string: $0) },
            onOpenEntity: ((UUID, EntityKind) -> Void)? = nil,
            onChooseRelease: ((UUID) -> Void)? = nil
        ) {
            self.section = section
            self.service = service
            self.referenceDate = referenceDate
            self.resolveAssetURL = resolveAssetURL
            self.onOpenEntity = onOpenEntity
            self.onChooseRelease = onChooseRelease
        }

        public var body: some View {
            content
                .searchable(text: $query, prompt: searchPrompt)
                .navigationTitle(selectedIDs.isEmpty ? section.title : "\(selectedIDs.count) Selected")
                .toolbar { toolbarContent }
                .refreshable { await refresh() }
                .overlay { overlayContent }
                .confirmationDialog(
                    removalTitle,
                    isPresented: removalPresented,
                    titleVisibility: .visible
                ) {
                    Button("Remove", role: .destructive) {
                        let ids = pendingRemovalIDs
                        pendingRemovalIDs = []
                        Task { await removeDownloads(ids) }
                    }
                    Button("Cancel", role: .cancel) { pendingRemovalIDs = [] }
                } message: {
                    Text(
                        "This removes the selected download data from the client. Monitored items remain Wanted and can search again."
                    )
                }
                .sheet(item: $selectedAcquisition) { item in
                    RequestActivityAcquisitionDetailView(
                        acquisitionID: item.id,
                        service: service
                    )
                }
                .task(id: taskIdentity) {
                    guard liveRefreshIsActive else { return }
                    await load(showSpinner: currentSourceIsEmpty)
                    await pollWhileVisible()
                }
                .onChange(of: section) {
                    selectedIDs = []
                    query = ""
                }
                .prismediaScreenBackground()
                .accessibilityIdentifier("request-activity.\(section.rawValue)")
        }

        @ViewBuilder
        private var content: some View {
            switch section {
            case .downloads:
                downloadList
            case .missing:
                wantedList(.missing)
            case .cutoffUnmet:
                wantedList(.cutoffUnmet)
            case .history:
                historyList
            }
        }

        private var downloadList: some View {
            RequestActivityDownloadList(
                selectedIDs: $selectedIDs,
                selectedStatus: $selectedStatus,
                selectedKind: $selectedDownloadKind,
                sort: $sort,
                items: visibleDownloads,
                availableKinds: downloadKinds,
                sourceIsEmpty: downloads.isEmpty,
                errorMessage: errorMessage,
                isActing: isActing,
                resolveAssetURL: resolveAssetURL,
                onPrimaryAction: performPrimaryAction,
                onManage: { selectedAcquisition = $0 },
                onOpenEntity: openDownloadEntity,
                onRemove: { pendingRemovalIDs = [$0.id] }
            )
        }

        private func wantedList(_ list: RequestActivityWantedList) -> some View {
            let totalPages = max(1, Int(ceil(Double(wantedPage?.total ?? 0) / 50)))
            return RequestActivityWantedListView(
                selectedIDs: $selectedIDs,
                selectedKind: $selectedWantedKind,
                page: $page,
                items: visibleWantedItems,
                list: list,
                totalPages: totalPages,
                sourceIsEmpty: wantedPage?.items.isEmpty ?? true,
                errorMessage: errorMessage,
                isLoading: isLoading,
                isActing: isActing,
                referenceDate: referenceDate,
                resolveAssetURL: resolveAssetURL,
                onSearchNow: requestSearchWanted,
                onOpenEntity: openWantedEntity,
                onUnmonitor: requestUnmonitor
            )
        }

        private var historyList: some View {
            RequestActivityHistoryList(
                entries: visibleHistory,
                sourceIsEmpty: history.isEmpty,
                errorMessage: errorMessage,
                referenceDate: referenceDate,
                onOpenEntity: openHistoryEntity
            )
        }

        @ViewBuilder
        private var overlayContent: some View {
            if isLoading && currentSourceIsEmpty {
                PrismediaLoadingView("Loading \(section.title.lowercased())…")
            } else if let errorMessage, currentSourceIsEmpty {
                ContentUnavailableView {
                    Label("Unable to Load \(section.title)", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    PrismediaButton(
                        "Try Again",
                        systemImage: "arrow.clockwise",
                        variant: .prominent
                    ) {
                        Task { await refresh() }
                    }
                }
            } else if let emptyState = currentEmptyState {
                RequestActivityEmptyView(section: section, state: emptyState, query: query)
            }
        }

        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            #if os(iOS)
                if section != .history {
                    ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)
                    ToolbarItemGroup(placement: trailingToolbarPlacement) {
                        if !selectedIDs.isEmpty {
                            selectionMenu
                        }
                        selectionToggleButton
                    }
                }
            #else
                if !selectedIDs.isEmpty {
                    ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)
                    ToolbarItem(placement: trailingToolbarPlacement) {
                        selectionMenu
                    }
                }
            #endif
        }

        private var selectionMenu: some View {
            RequestActivitySelectionMenu(
                section: section,
                selectedCount: selectedIDs.count,
                onRemove: { pendingRemovalIDs = selectedIDs },
                onSearch: requestSearchSelected,
                onUnmonitor: requestUnmonitorSelected
            )
        }

        #if os(iOS)
            private var selectionToggleButton: some View {
                RequestActivitySelectionToggle(
                    isEditing: editMode?.wrappedValue.isEditing == true
                ) {
                    withAnimation {
                        if editMode?.wrappedValue.isEditing == true {
                            editMode?.wrappedValue = .inactive
                            selectedIDs.removeAll()
                        } else {
                            editMode?.wrappedValue = .active
                        }
                    }
                }
            }
        #endif

        private func requestSearchSelected() {
            let targets = wantedPage?.items.filter { selectedIDs.contains($0.id) } ?? []
            Task { await searchWanted(targets) }
        }

        private func requestUnmonitorSelected() {
            let targets = wantedPage?.items.filter { selectedIDs.contains($0.id) } ?? []
            Task { await unmonitor(targets) }
        }

        private func requestSearchWanted(_ item: RequestActivityWantedItem) {
            Task { await searchWanted([item]) }
        }

        private func requestUnmonitor(_ item: RequestActivityWantedItem) {
            Task { await unmonitor([item]) }
        }

        private var trailingToolbarPlacement: ToolbarItemPlacement {
            #if os(iOS)
                .topBarTrailing
            #else
                .primaryAction
            #endif
        }

        private var visibleDownloads: [RequestActivityDownload] {
            RequestActivityDownloadFilter(
                query: query,
                status: selectedStatus,
                kind: selectedDownloadKind,
                sort: sort
            ).apply(to: downloads)
        }

        private var visibleWantedItems: [RequestActivityWantedItem] {
            let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !needle.isEmpty else { return wantedPage?.items ?? [] }
            return wantedPage?.items.filter {
                $0.title.localizedCaseInsensitiveContains(needle)
                    || $0.author?.localizedCaseInsensitiveContains(needle) == true
            } ?? []
        }

        private var visibleHistory: [RequestActivityHistoryEntry] {
            let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !needle.isEmpty else { return history }
            return history.filter {
                $0.title.localizedCaseInsensitiveContains(needle)
                    || $0.releaseTitle?.localizedCaseInsensitiveContains(needle) == true
                    || $0.message?.localizedCaseInsensitiveContains(needle) == true
            }
        }

        private var downloadKinds: [EntityKind] {
            Array(Set(downloads.map(\.kind))).sorted {
                $0.displayLabel.localizedStandardCompare($1.displayLabel) == .orderedAscending
            }
        }

        private var currentEmptyState: RequestActivityEmptyState? {
            switch section {
            case .downloads:
                RequestActivityEmptyState.resolve(
                    sourceCount: downloads.count,
                    visibleCount: visibleDownloads.count
                )
            case .missing, .cutoffUnmet:
                RequestActivityEmptyState.resolve(
                    sourceCount: wantedPage?.items.count ?? 0,
                    visibleCount: visibleWantedItems.count
                )
            case .history:
                RequestActivityEmptyState.resolve(
                    sourceCount: history.count,
                    visibleCount: visibleHistory.count
                )
            }
        }

        private var currentSourceIsEmpty: Bool {
            switch section {
            case .downloads: downloads.isEmpty
            case .missing, .cutoffUnmet: wantedPage?.items.isEmpty ?? true
            case .history: history.isEmpty
            }
        }

        private var searchPrompt: String {
            switch section {
            case .downloads: "Search downloads"
            case .missing, .cutoffUnmet: "Search this page"
            case .history: "Search history"
            }
        }

        private var loadIdentity: String {
            "\(section.rawValue)-\(page)-\(selectedWantedKind?.rawValue ?? "all")"
        }

        private var taskIdentity: String {
            "\(loadIdentity)-\(liveRefreshIsActive)"
        }

        private var liveRefreshIsActive: Bool {
            pageIsActive && scenePhase == .active && selectedAcquisition == nil
        }

        private var removalPresented: Binding<Bool> {
            Binding(
                get: { !pendingRemovalIDs.isEmpty },
                set: { presented in if !presented { pendingRemovalIDs = [] } }
            )
        }

        private var removalTitle: String {
            let count = pendingRemovalIDs.count
            return "Remove \(count) \(count == 1 ? "Download" : "Downloads")?"
        }

        private func load(showSpinner: Bool, reportsErrors: Bool = true) async {
            if showSpinner { isLoading = true }
            defer { if showSpinner { isLoading = false } }
            do {
                switch section {
                case .downloads:
                    let nextDownloads = try await service.listRequestActivityDownloads()
                    if downloads != nextDownloads { downloads = nextDownloads }
                case .missing:
                    let nextPage = try await service.listRequestActivityWanted(
                        .missing,
                        page: page,
                        pageSize: 50,
                        kind: selectedWantedKind
                    )
                    if wantedPage != nextPage { wantedPage = nextPage }
                case .cutoffUnmet:
                    let nextPage = try await service.listRequestActivityWanted(
                        .cutoffUnmet,
                        page: page,
                        pageSize: 50,
                        kind: selectedWantedKind
                    )
                    if wantedPage != nextPage { wantedPage = nextPage }
                case .history:
                    let nextHistory = try await service.listRequestActivityHistory(limit: 200, entityID: nil)
                    if history != nextHistory { history = nextHistory }
                }
                if errorMessage != nil { errorMessage = nil }
                let validSelection = selectedIDs.intersection(currentIDs)
                if selectedIDs != validSelection { selectedIDs = validSelection }
            } catch is CancellationError {
                return
            } catch {
                if reportsErrors { errorMessage = error.localizedDescription }
            }
        }

        private func refresh() async {
            await load(showSpinner: currentSourceIsEmpty)
        }

        private func pollWhileVisible() async {
            while liveRefreshIsActive {
                do {
                    try await Task.sleep(for: liveRefreshInterval)
                } catch {
                    return
                }
                guard !Task.isCancelled, liveRefreshIsActive else { return }
                await load(showSpinner: false, reportsErrors: false)
            }
        }

        private var liveRefreshInterval: Duration {
            if section == .downloads,
                downloads.contains(where: { RequestActivityStatusPolicy.shouldPoll($0.status) })
            {
                return .seconds(4)
            }
            return .seconds(12)
        }

        private var currentIDs: Set<UUID> {
            switch section {
            case .downloads: Set(downloads.map(\.id))
            case .missing, .cutoffUnmet: Set((wantedPage?.items ?? []).map(\.id))
            case .history: []
            }
        }

        private func performPrimaryAction(_ item: RequestActivityDownload) {
            switch RequestActivityStatusPolicy.primaryAction(
                for: item.status,
                hasEntity: item.entityID != nil
            ) {
            case .chooseRelease:
                if let onChooseRelease {
                    onChooseRelease(item.id)
                } else {
                    selectedAcquisition = item
                }
            case .searchAgain:
                Task { await research(item) }
            case .view:
                openDownloadEntity(item)
            case nil:
                break
            }
        }

        private func openDownloadEntity(_ item: RequestActivityDownload) {
            guard let entityID = item.entityID else { return }
            onOpenEntity?(entityID, item.kind)
        }

        private func openWantedEntity(_ item: RequestActivityWantedItem) {
            guard let entityID = item.entityID else { return }
            onOpenEntity?(entityID, item.kind)
        }

        private func openHistoryEntity(_ entry: RequestActivityHistoryEntry) {
            guard let entityID = entry.entityID else { return }
            onOpenEntity?(entityID, entry.kind)
        }

        private func research(_ item: RequestActivityDownload) async {
            guard !isActing else { return }
            isActing = true
            defer { isActing = false }
            do {
                _ = try await service.researchRequestActivityAcquisition(id: item.id)
                await load(showSpinner: false)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        private func removeDownloads(_ ids: Set<UUID>) async {
            guard !ids.isEmpty, !isActing else { return }
            isActing = true
            defer { isActing = false }
            let titles = Dictionary(uniqueKeysWithValues: downloads.map { ($0.id, $0.title) })
            var failures: [String] = []
            for id in ids {
                do {
                    try await service.removeRequestActivityAcquisition(id: id)
                } catch {
                    failures.append("\(titles[id] ?? id.uuidString): \(error.localizedDescription)")
                }
            }
            selectedIDs = []
            await load(showSpinner: false)
            if !failures.isEmpty {
                errorMessage =
                    RequestActivityRemovalSummary(
                        attempted: ids.count,
                        failures: failures
                    ).message
            }
        }

        private func searchWanted(_ targets: [RequestActivityWantedItem]) async {
            guard !targets.isEmpty, !isActing else { return }
            isActing = true
            defer { isActing = false }
            var failures: [String] = []
            for item in targets {
                guard let acquisitionID = item.acquisitionID else { continue }
                do {
                    _ = try await service.researchRequestActivityAcquisition(id: acquisitionID)
                } catch {
                    failures.append("\(item.title): \(error.localizedDescription)")
                }
            }
            selectedIDs = []
            await load(showSpinner: false)
            if !failures.isEmpty { errorMessage = failures.joined(separator: " · ") }
        }

        private func unmonitor(_ targets: [RequestActivityWantedItem]) async {
            guard !targets.isEmpty, !isActing else { return }
            isActing = true
            defer { isActing = false }
            var failures: [String] = []
            for item in targets {
                do {
                    _ = try await service.unmonitor(id: item.id)
                } catch {
                    failures.append("\(item.title): \(error.localizedDescription)")
                }
            }
            selectedIDs = []
            await load(showSpinner: false)
            if !failures.isEmpty { errorMessage = failures.joined(separator: " · ") }
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Content") {
        NavigationStack {
            RequestActivitySurface(
                section: .downloads,
                service: PreviewRequestActivityService(scenario: .content),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
        }
    }

    #Preview("Loading") {
        NavigationStack {
            RequestActivitySurface(
                section: .downloads,
                service: PreviewRequestActivityService(scenario: .loading),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
        }
    }

    #Preview("Empty") {
        NavigationStack {
            RequestActivitySurface(
                section: .cutoffUnmet,
                service: PreviewRequestActivityService(scenario: .empty),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
        }
    }

    #Preview("Error") {
        NavigationStack {
            RequestActivitySurface(
                section: .history,
                service: PreviewRequestActivityService(scenario: .error),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
        }
    }

    #Preview("Dark") {
        NavigationStack {
            RequestActivitySurface(
                section: .downloads,
                service: PreviewRequestActivityService(scenario: .content),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Accessibility Type") {
        NavigationStack {
            RequestActivitySurface(
                section: .missing,
                service: PreviewRequestActivityService(scenario: .content),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
        }
        .dynamicTypeSize(.accessibility3)
    }
#endif
