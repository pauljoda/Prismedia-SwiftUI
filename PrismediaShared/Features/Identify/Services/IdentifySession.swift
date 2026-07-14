import Foundation
import Observation

#if os(iOS) || os(macOS)
    @Observable @MainActor
    final class IdentifySession {
        private(set) var queue: [AdministrativeIdentifyQueueItem] = []
        private(set) var providers: [AdministrativePlugin] = []
        private(set) var browseItems: [EntityThumbnail] = []
        private(set) var isLoading = false
        private(set) var isBrowsing = false
        private(set) var isSearching = false
        private(set) var isSeeking = false
        private(set) var isApplying = false
        private(set) var applyProgress: AdministrativeIdentifyApplyProgress?
        private(set) var bulkProgress: IdentifyBulkProgress?
        var selectedItemID: UUID?
        var selectedQueueIDs = Set<UUID>()
        var selectedKind: EntityKind?
        var browseFilter = IdentifyBrowseFilter.unorganized
        var browseSearch = ""
        var selectedBrowseIDs = Set<UUID>()
        var selectedProviderID = ""
        var searchValues: [String: String] = [:]
        var reviewSelection = MetadataReviewSelection()
        var showsSearchForProposal = false
        var errorMessage: String?

        private let service: any AdministrationServicing
        private let browser: any IdentifyEntityBrowsing
        let hidesNsfw: Bool
        private let pollingPolicy: IdentifyPollingPolicy
        private let sleep: @Sendable (Duration) async throws -> Void
        private let now: @Sendable () -> Date
        private var pollingToken = UUID()

        init(
            service: any AdministrationServicing,
            browser: any IdentifyEntityBrowsing,
            hidesNsfw: Bool = true,
            pollingPolicy: IdentifyPollingPolicy = .init(),
            sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
            now: @escaping @Sendable () -> Date = Date.init,
            initialQueue: [AdministrativeIdentifyQueueItem] = [],
            initialProviders: [AdministrativePlugin] = []
        ) {
            self.service = service
            self.browser = browser
            self.hidesNsfw = hidesNsfw
            self.pollingPolicy = pollingPolicy
            self.sleep = sleep
            self.now = now
            queue = initialQueue
            providers = initialProviders
            selectedItemID = initialQueue.first?.entityID
            reviewSelection = initialQueue.first?.proposal.map(MetadataReviewPolicy.seededSelection) ?? .init()
        }

        var kindSummaries: [IdentifyKindSummary] {
            let supported = Set(
                providers.filter {
                    $0.installed && $0.enabled && $0.missingAuthKeys.isEmpty && (!hidesNsfw || !$0.isNsfw)
                }
                .flatMap(\.supports)
                .filter(IdentifyProviderPolicy.supportsIdentify)
                .map { EntityKind(rawValue: $0.entityKind) })
            return supported.map { kind in
                IdentifyKindSummary(
                    kind: kind,
                    pendingCount: queue.count {
                        $0.entityKind == kind && !IdentifyQueueState(rawServerValue: $0.state).isTerminal
                    })
            }.sorted { $0.kind.displayLabel.localizedStandardCompare($1.kind.displayLabel) == .orderedAscending }
        }

        var selectedItem: AdministrativeIdentifyQueueItem? {
            queue.first { $0.entityID == selectedItemID }
        }

        var reviewableIDs: [UUID] {
            queue.filter { IdentifyQueueState(rawServerValue: $0.state).isReviewable }.map(\.entityID)
        }

        var providersForSelectedItem: [AdministrativePlugin] {
            guard let selectedItem else { return [] }
            return PluginSearchFieldPolicy.eligibleProviders(
                providers, entityKind: selectedItem.entityKind.rawValue, hidesNsfw: hidesNsfw)
        }

        var canAcceptQueueSelection: Bool {
            queue.contains {
                selectedQueueIDs.contains($0.entityID)
                    && IdentifyBulkBehavior.canAccept(
                        state: .init(rawServerValue: $0.state), hasProposal: $0.proposal != nil,
                        cascadeRunning: $0.cascadeRunning)
            }
        }

        func load() async {
            isLoading = true
            defer { isLoading = false }
            do {
                async let loadedProviders = service.identifyProviders(kind: nil)
                async let loadedQueue = service.identifyQueue()
                let (providers, queue) = try await (loadedProviders, loadedQueue)
                self.providers = providers
                self.queue = queue
                if selectedItemID == nil { select(queue.first?.entityID) } else { select(selectedItemID) }
                reconcileProvider()
            } catch { errorMessage = error.localizedDescription }
        }

        func open(entityID: UUID) async {
            cancelPolling()
            do {
                let item: AdministrativeIdentifyQueueItem
                do {
                    item = try await service.identifyQueueItem(entityID: entityID)
                } catch PrismediaAPIError.httpStatus(404, _) {
                    item = try await service.addIdentifyItem(entityID: entityID)
                }
                replace(item)
                select(entityID)
                reconcileProvider()
            } catch { errorMessage = error.localizedDescription }
        }

        func search(fields: [String: String]) async {
            guard let item = selectedItem, !selectedProviderID.isEmpty else { return }
            guard let provider = providersForSelectedItem.first(where: { $0.id == selectedProviderID }) else { return }
            let definitions =
                PluginSearchFieldPolicy.support(
                    in: provider, entityKind: item.entityKind.rawValue)?.search?.fields ?? []
            let query = AdministrativeIdentifyQuery(
                title: PluginSearchFieldPolicy.compatibilityTitle(
                    fields: definitions, values: fields, fallback: item.title),
                requireChoice: true, fields: fields, limit: 25)
            await beginSearch(entityID: item.entityID, provider: selectedProviderID, query: query)
        }

        func rescan() async {
            guard let item = selectedItem, !selectedProviderID.isEmpty else { return }
            await beginSearch(entityID: item.entityID, provider: selectedProviderID, query: nil)
        }

        func seek() async {
            guard let item = selectedItem else { return }
            isSeeking = true
            defer { isSeeking = false }
            let order = IdentifyProviderOrder.ids(
                selected: selectedProviderID, providers: providers, kind: item.entityKind, hidesNsfw: hidesNsfw)
            for providerID in order {
                guard !Task.isCancelled else { return }
                selectedProviderID = providerID
                let result = await searchAndPoll(entityID: item.entityID, provider: providerID, query: nil)
                if result?.proposal != nil || !(result?.candidates.isEmpty ?? true) { return }
            }
            errorMessage = "No provider found a match."
        }

        func resolve(_ candidate: AdministrativeEntitySearchCandidate) async {
            guard let item = selectedItem, !selectedProviderID.isEmpty else { return }
            isSearching = true
            defer { isSearching = false }
            do {
                let updated = try await service.resolveIdentifyCandidate(
                    entityID: item.entityID, provider: selectedProviderID, candidate: candidate)
                receive(updated)
                showsSearchForProposal = false
            } catch { errorMessage = error.localizedDescription }
        }

        func apply(advance: Bool) async {
            guard let item = selectedItem, let proposal = item.proposal, !item.cascadeRunning else { return }
            isApplying = true
            applyProgress = nil
            let started = now()
            let progressID = UUID()
            do {
                let filtered = MetadataReviewPolicy.proposalForApply(proposal, selection: reviewSelection)
                let updated = try await service.applyIdentifyItem(
                    entityID: item.entityID, proposal: filtered,
                    selectedFields: MetadataReviewPolicy.selectedRootFields(for: proposal, selection: reviewSelection),
                    selectedImages: MetadataReviewPolicy.selectedRootImages(for: proposal, selection: reviewSelection),
                    progressID: progressID)
                replace(updated)
                await pollApply(entityID: item.entityID, progressID: progressID, started: started)
                if advance { selectNext() }
            } catch { errorMessage = error.localizedDescription }
            isApplying = false
        }

        func reject(advance: Bool) async {
            guard let item = selectedItem else { return }
            do {
                try await service.removeIdentifyItem(entityID: item.entityID)
                queue.removeAll { $0.entityID == item.entityID }
                if advance { selectNext() } else { selectedItemID = nil }
            } catch { errorMessage = error.localizedDescription }
        }

        func acceptSelected() async {
            let items = queue.filter {
                selectedQueueIDs.contains($0.entityID)
                    && IdentifyBulkBehavior.canAccept(
                        state: .init(rawServerValue: $0.state), hasProposal: $0.proposal != nil,
                        cascadeRunning: $0.cascadeRunning)
            }
            bulkProgress = .init(completed: 0, total: items.count)
            for (index, item) in items.enumerated() {
                guard let proposal = item.proposal else { continue }
                do {
                    let selection = MetadataReviewPolicy.seededSelection(for: proposal)
                    let updated = try await service.applyIdentifyItem(
                        entityID: item.entityID,
                        proposal: MetadataReviewPolicy.proposalForApply(proposal, selection: selection),
                        selectedFields: MetadataReviewPolicy.selectedRootFields(for: proposal, selection: selection),
                        selectedImages: MetadataReviewPolicy.selectedRootImages(for: proposal, selection: selection),
                        progressID: nil)
                    replace(updated)
                } catch { errorMessage = error.localizedDescription }
                bulkProgress = .init(completed: index + 1, total: items.count)
            }
            selectedQueueIDs.removeAll()
        }

        func rejectSelected() async {
            let ids = selectedQueueIDs
            var removedIDs = Set<UUID>()
            bulkProgress = .init(completed: 0, total: ids.count)
            for (index, id) in ids.enumerated() {
                do {
                    try await service.removeIdentifyItem(entityID: id)
                    removedIDs.insert(id)
                } catch {
                    errorMessage = error.localizedDescription
                }
                bulkProgress = .init(completed: index + 1, total: ids.count)
            }
            queue.removeAll { removedIDs.contains($0.entityID) }
            selectedQueueIDs.subtract(removedIDs)
        }

        func browse(kind: EntityKind) async {
            selectedKind = kind
            reconcileBrowseProvider(for: kind)
            isBrowsing = true
            defer { isBrowsing = false }
            do {
                browseItems = try await browser.entities(
                    kind: kind, organized: browseFilter == .unorganized ? false : nil,
                    search: browseSearch.isEmpty ? nil : browseSearch)
            } catch { errorMessage = error.localizedDescription }
        }

        func queueSelectedBrowseItems() async {
            guard !selectedProviderID.isEmpty, !selectedBrowseIDs.isEmpty else { return }
            guard let selectedKind,
                PluginSearchFieldPolicy.eligibleProviders(
                    providers,
                    entityKind: selectedKind.rawValue,
                    hidesNsfw: hidesNsfw
                ).contains(where: { $0.id == selectedProviderID })
            else { return }
            do {
                _ = try await service.startBulkIdentify(
                    provider: selectedProviderID, entityIDs: Array(selectedBrowseIDs), query: nil)
                selectedBrowseIDs.removeAll()
                await load()
            } catch { errorMessage = error.localizedDescription }
        }

        func reviewAll() { select(reviewableIDs.first) }
        func selectNext() { select(IdentifyNextFlow.next(after: selectedItemID, in: reviewableIDs)) }
        func selectPrevious() { select(IdentifyNextFlow.previous(before: selectedItemID, in: reviewableIDs)) }
        func returnToSearch() { showsSearchForProposal = true }

        func cancelPolling() {
            pollingToken = UUID()
        }

        private func beginSearch(entityID: UUID, provider: String, query: AdministrativeIdentifyQuery?) async {
            isSearching = true
            defer { isSearching = false }
            _ = await searchAndPoll(entityID: entityID, provider: provider, query: query)
        }

        private func searchAndPoll(entityID: UUID, provider: String, query: AdministrativeIdentifyQuery?) async
            -> AdministrativeIdentifyQueueItem?
        {
            let token = UUID()
            pollingToken = token
            do {
                var item = try await service.searchIdentifyItem(entityID: entityID, provider: provider, query: query)
                receive(item)
                let started = now()
                while true {
                    let elapsed = now().timeIntervalSince(started)
                    switch IdentifyPollingDecision.resolve(
                        state: .init(rawServerValue: item.state), elapsed: elapsed,
                        isCancelled: pollingToken != token || Task.isCancelled, policy: pollingPolicy)
                    {
                    case .complete: return item
                    case .timedOut, .cancelled: return nil
                    case .continuePolling: break
                    }
                    try await sleep(pollingPolicy.searchInterval(elapsed: elapsed))
                    try Task.checkCancellation()
                    item = try await service.identifyQueueItem(entityID: entityID)
                    receive(item)
                }
            } catch is CancellationError { return nil } catch {
                errorMessage = error.localizedDescription
                return nil
            }
        }

        private func pollApply(entityID: UUID, progressID: UUID, started: Date) async {
            let token = UUID()
            pollingToken = token
            do {
                while true {
                    guard pollingToken == token else { return }
                    let elapsed = now().timeIntervalSince(started)
                    let progress: AdministrativeIdentifyApplyProgress
                    do {
                        progress = try await service.identifyApplyProgress(
                            entityID: entityID, progressID: progressID)
                    } catch PrismediaAPIError.httpStatus(404, _) {
                        try await sleep(pollingPolicy.applyInterval(elapsed: elapsed))
                        continue
                    }
                    applyProgress = progress
                    if ["done", "error", "failed", "cancelled"].contains(progress.state.lowercased()) {
                        let remaining = max(0, pollingPolicy.minimumApplyVisibilitySeconds - elapsed)
                        if remaining > 0 { try await sleep(.milliseconds(Int64(remaining * 1_000))) }
                        return
                    }
                    try await sleep(pollingPolicy.applyInterval(elapsed: elapsed))
                }
            } catch is CancellationError {} catch { errorMessage = error.localizedDescription }
        }

        private func receive(_ item: AdministrativeIdentifyQueueItem) {
            replace(item)
            reviewSelection = item.proposal.map(MetadataReviewPolicy.seededSelection) ?? .init()
            if item.proposal != nil { showsSearchForProposal = false }
        }

        private func replace(_ item: AdministrativeIdentifyQueueItem) {
            if let index = queue.firstIndex(where: { $0.entityID == item.entityID }) {
                queue[index] = item
            } else {
                queue.insert(item, at: 0)
            }
        }

        private func reconcileProvider() {
            guard let item = selectedItem else { return }
            let eligible = PluginSearchFieldPolicy.eligibleProviders(
                providers, entityKind: item.entityKind.rawValue, hidesNsfw: hidesNsfw)
            if !eligible.contains(where: { $0.id == selectedProviderID }) {
                selectedProviderID = eligible.first?.id ?? ""
            }
        }

        private func reconcileBrowseProvider(for kind: EntityKind) {
            let eligible = providers.filter { provider in
                provider.installed && provider.enabled && provider.missingAuthKeys.isEmpty
                    && (!hidesNsfw || !provider.isNsfw)
                    && provider.supports.contains {
                        $0.entityKind == kind.rawValue && IdentifyProviderPolicy.supportsIdentify($0)
                    }
            }
            if !eligible.contains(where: { $0.id == selectedProviderID }) {
                selectedProviderID = eligible.first?.id ?? ""
            }
        }

        private func select(_ entityID: UUID?) {
            selectedItemID = entityID
            let proposal = queue.first { $0.entityID == entityID }?.proposal
            reviewSelection = proposal.map(MetadataReviewPolicy.seededSelection) ?? .init()
            showsSearchForProposal = false
            reconcileProvider()
        }
    }
#endif
