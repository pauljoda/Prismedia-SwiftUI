import Foundation
import Observation

#if os(iOS) || os(macOS)
    @Observable @MainActor
    final class IdentifySession {
        private(set) var queue: [AdministrativeIdentifyQueueItem] = []
        private(set) var providers: [AdministrativePlugin] = []
        private(set) var defaultProviderIDs: [String: String] = [:]
        private(set) var isLoading = false
        private(set) var isSearching = false
        private(set) var isLoadingMore = false
        private(set) var isRescanning = false
        private(set) var isSeeking = false
        private(set) var isResolving = false
        private(set) var isApplying = false
        private(set) var applyProgress: AdministrativeIdentifyApplyProgress?
        private(set) var bulkProgress: IdentifyBulkProgress?
        private(set) var entityDetailsByID: [UUID: EntityDetail] = [:]
        private(set) var entityDetailLoadingIDs = Set<UUID>()
        var selectedItemID: UUID?
        var selectedQueueIDs = Set<UUID>()
        var selectedKind: EntityKind?
        var selectedProviderID = ""
        var searchValues: [String: String] = [:]
        private(set) var searchLimit = 25
        private(set) var activeCandidateID: PluginSearchCandidateIdentity?
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
        private var openingEntryIDs = Set<UUID>()
        private var searchValuesByEntityAndProvider: [String: [String: String]] = [:]
        private var retainedCandidatesBySearchContext: [String: [AdministrativeEntitySearchCandidate]] = [:]
        private var retryOperation: IdentifySearchRetryOperation?

        private static let searchPageSize = PluginSearchPagingPolicy.pageSize
        private static let searchMaxLimit = PluginSearchPagingPolicy.maximumLimit

        init(
            service: any AdministrationServicing,
            browser: any IdentifyEntityBrowsing,
            hidesNsfw: Bool = true,
            pollingPolicy: IdentifyPollingPolicy = .init(),
            sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
            now: @escaping @Sendable () -> Date = Date.init,
            initialQueue: [AdministrativeIdentifyQueueItem] = [],
            initialProviders: [AdministrativePlugin] = [],
            initialDefaultProviderIDs: [String: String] = [:],
            initialEntityDetail: EntityDetail? = nil
        ) {
            self.service = service
            self.browser = browser
            self.hidesNsfw = hidesNsfw
            self.pollingPolicy = pollingPolicy
            self.sleep = sleep
            self.now = now
            queue = initialQueue
            providers = initialProviders
            defaultProviderIDs = initialDefaultProviderIDs
            if let initialEntityDetail {
                entityDetailsByID[initialEntityDetail.id] = initialEntityDetail
            }
            selectedItemID = initialQueue.first?.entityID
            reviewSelection = initialQueue.first?.proposal.map(MetadataReviewPolicy.seededSelection) ?? .init()
            reconcileProvider(preferConfiguredDefault: true)
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

        var selectedEntityDetail: EntityDetail? {
            guard let selectedItemID else { return nil }
            return entityDetailsByID[selectedItemID]
        }

        var selectedEntityThumbnail: EntityThumbnail? {
            selectedEntityDetail?.identifyThumbnail
        }

        var isLoadingSelectedEntityDetail: Bool {
            guard let selectedItemID else { return false }
            return entityDetailLoadingIDs.contains(selectedItemID)
        }

        var reviewableIDs: [UUID] {
            queue.filter { IdentifyQueueState(rawServerValue: $0.state).isReviewable }.map(\.entityID)
        }

        var providersForSelectedItem: [AdministrativePlugin] {
            guard let selectedItem else { return [] }
            return RequestIdentifyProviderPreferencePolicy.identifyProviders(
                providers,
                entityKind: selectedItem.entityKind.rawValue,
                defaultProviderIDs: defaultProviderIDs,
                hidesNsfw: hidesNsfw
            )
        }

        var isSearchBusy: Bool {
            isSearching || isLoadingMore || isRescanning || isSeeking || isResolving
        }

        var canLoadMoreSearchCandidates: Bool {
            guard let item = selectedItem else { return false }
            let candidates = searchCandidates(for: item)
            return !candidates.isEmpty
                && candidates.count >= searchLimit
                && searchLimit < Self.searchMaxLimit
        }

        func defaultProviderID(for kind: EntityKind) -> String? {
            RequestIdentifyProviderPreferencePolicy.defaultProviderID(
                for: kind.rawValue,
                in: defaultProviderIDs
            )
        }

        var canAcceptQueueSelection: Bool {
            queue.contains {
                selectedQueueIDs.contains($0.entityID)
                    && IdentifyBulkBehavior.canAccept(
                        state: .init(rawServerValue: $0.state), hasProposal: $0.proposal != nil,
                        cascadeRunning: $0.cascadeRunning)
            }
        }

        var browseGridLoader: any EntityGridLoading {
            IdentifyEntityGridLoader(
                browser: browser,
                allowsNsfwContent: !hidesNsfw
            )
        }

        func load() async {
            isLoading = true
            defer { isLoading = false }
            do {
                async let loadedProviders = service.identifyProviders(kind: nil)
                async let loadedQueue = service.identifyQueue()
                async let loadedDefaults = loadDefaultProviderIDs()
                let (nextProviders, nextQueue, nextDefaults) = try await (
                    loadedProviders,
                    loadedQueue,
                    loadedDefaults
                )
                if providers != nextProviders { providers = nextProviders }
                if queue != nextQueue { queue = nextQueue }
                if let nextDefaults, defaultProviderIDs != nextDefaults {
                    defaultProviderIDs = nextDefaults
                }
                if selectedItemID == nil { select(nextQueue.first?.entityID) } else { select(selectedItemID) }
                reconcileProvider(preferConfiguredDefault: true)
                await loadSelectedEntityDetail()
                if errorMessage != nil { errorMessage = nil }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        func refreshQueue() async {
            do {
                let nextQueue = try await service.identifyQueue()
                receiveQueueRefresh(nextQueue)
            } catch is CancellationError {
                return
            } catch {
                // Background refreshes retain the last good queue and stay unobtrusive.
            }
        }

        func refreshSelectedItem() async {
            guard let selectedItemID else { return }
            do {
                let previousProposal = selectedItem?.proposal
                let refreshedItem = try await service.identifyQueueItem(entityID: selectedItemID)
                let previousProposalID = previousProposal?.proposalID
                replace(refreshedItem)
                if previousProposalID != refreshedItem.proposal?.proposalID {
                    reviewSelection = refreshedItem.proposal.map(MetadataReviewPolicy.seededSelection) ?? .init()
                    showsSearchForProposal = refreshedItem.proposal == nil
                } else if let proposal = refreshedItem.proposal {
                    reviewSelection = MetadataReviewPolicy.mergingSeededDefaults(
                        from: previousProposal,
                        to: proposal,
                        into: reviewSelection
                    )
                }
                reconcileProvider()
            } catch is CancellationError {
                return
            } catch PrismediaAPIError.httpStatus(404, _) {
                queue.removeAll { $0.entityID == selectedItemID }
                self.selectedItemID = nil
            } catch {
                // A live refresh retains the last usable review state and retries quietly.
            }
        }

        func refreshProviders() async {
            do {
                async let loadedProviders = service.identifyProviders(kind: nil)
                async let loadedDefaults = loadDefaultProviderIDs()
                let (nextProviders, nextDefaults) = try await (
                    loadedProviders,
                    loadedDefaults
                )
                if providers != nextProviders { providers = nextProviders }
                if let nextDefaults, defaultProviderIDs != nextDefaults {
                    defaultProviderIDs = nextDefaults
                }
                reconcileProvider(preferConfiguredDefault: false)
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
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
                await loadSelectedEntityDetail()
            } catch { errorMessage = error.localizedDescription }
        }

        func beginEntry(entityID: UUID) async {
            guard openingEntryIDs.insert(entityID).inserted else { return }
            defer { openingEntryIDs.remove(entityID) }

            cancelPolling()
            isLoading = true
            defer { isLoading = false }
            errorMessage = nil

            let item: AdministrativeIdentifyQueueItem
            var createdQueueItem = false
            do {
                do {
                    item = try await service.identifyQueueItem(entityID: entityID)
                } catch PrismediaAPIError.httpStatus(404, _) {
                    // Persist the queue record before presenting Search so the Identify
                    // dashboard can resume it if this presentation goes away.
                    item = try await service.addIdentifyItem(entityID: entityID)
                    createdQueueItem = true
                }

                replace(item)
                select(entityID)
                await loadSelectedEntityDetail()

                async let loadedProviders = loadProviders(kind: item.entityKind.rawValue)
                async let loadedDefaults = loadDefaultProviderIDs()
                let (nextProviders, nextDefaults) = await (
                    loadedProviders,
                    loadedDefaults
                )
                if let nextProviders, providers != nextProviders {
                    providers = nextProviders
                }
                if let nextDefaults, defaultProviderIDs != nextDefaults {
                    defaultProviderIDs = nextDefaults
                }
                reconcileProvider(preferConfiguredDefault: true)

                if createdQueueItem,
                    let requested = try? await service.searchIdentifyItem(
                        entityID: entityID,
                        provider: nil,
                        query: nil
                    )
                {
                    receive(requested)
                }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        func search(fields: [String: String]) async {
            searchLimit = Self.searchPageSize
            await performSearch(fields: fields, limit: searchLimit, loadingMore: false)
        }

        func loadMoreSearchCandidates() async {
            guard canLoadMoreSearchCandidates else { return }
            guard let nextLimit = PluginSearchPagingPolicy.nextLimit(after: searchLimit) else { return }
            searchLimit = nextLimit
            await performSearch(fields: searchValues, limit: searchLimit, loadingMore: true)
        }

        private func performSearch(
            fields: [String: String],
            limit: Int,
            loadingMore: Bool
        ) async {
            guard let item = selectedItem, !selectedProviderID.isEmpty else { return }
            guard
                let provider = providersForSelectedItem.first(where: {
                    $0.id.caseInsensitiveCompare(selectedProviderID) == .orderedSame
                })
            else { return }
            let definitions =
                PluginSearchFieldPolicy.searchSupport(
                    in: provider, entityKind: item.entityKind.rawValue)?.search?.fields ?? []
            let query = AdministrativeIdentifyQuery(
                title: PluginSearchFieldPolicy.compatibilityTitle(
                    fields: definitions, values: fields, fallback: item.title),
                requireChoice: true, fields: fields, limit: limit)
            rememberCurrentSearchValues()
            retainCandidates(for: item)
            retryOperation = .search(fields: fields, limit: limit)

            if loadingMore {
                isLoadingMore = true
                errorMessage = nil
                defer { isLoadingMore = false }
                _ = await searchAndPoll(
                    entityID: item.entityID,
                    provider: provider.id,
                    query: query
                )
            } else {
                await beginSearch(entityID: item.entityID, provider: provider.id, query: query)
            }
        }

        func rescan() async {
            guard let item = selectedItem, !selectedProviderID.isEmpty else { return }
            retainCandidates(for: item)
            retryOperation = .rescan
            isRescanning = true
            errorMessage = nil
            defer { isRescanning = false }
            _ = await searchAndPoll(entityID: item.entityID, provider: selectedProviderID, query: nil)
        }

        func seek() async {
            guard let item = selectedItem else { return }
            retainCandidates(for: item)
            retryOperation = .seek
            isSeeking = true
            errorMessage = nil
            defer { isSeeking = false }
            let order = IdentifyProviderOrder.ids(
                selected: selectedProviderID,
                providers: providers,
                kind: item.entityKind,
                hidesNsfw: hidesNsfw,
                defaultProviderIDs: defaultProviderIDs
            )
            for providerID in order {
                guard !Task.isCancelled else { return }
                selectProvider(providerID)
                let result = await searchAndPoll(entityID: item.entityID, provider: providerID, query: nil)
                if result?.proposal != nil || !(result?.candidates.isEmpty ?? true) { return }
            }
            errorMessage = "No provider found a match."
        }

        func resolve(_ candidate: AdministrativeEntitySearchCandidate) async {
            guard let item = selectedItem, !selectedProviderID.isEmpty else { return }
            retainCandidates(for: item)
            retryOperation = .resolve(candidate)
            activeCandidateID = candidate.pluginSearchIdentity
            isResolving = true
            errorMessage = nil
            defer { isResolving = false }
            do {
                let updated = try await service.resolveIdentifyCandidate(
                    entityID: item.entityID, provider: selectedProviderID, candidate: candidate)
                receive(updated)
                showsSearchForProposal = false
            } catch {
                activeCandidateID = nil
                errorMessage = error.localizedDescription
            }
        }

        func retryLastSearchOperation() async {
            guard let retryOperation else {
                await rescan()
                return
            }
            switch retryOperation {
            case .search(let fields, let limit):
                searchLimit = limit
                let hasRetainedCandidates =
                    selectedItem.map {
                        !searchCandidates(for: $0).isEmpty
                    } ?? false
                await performSearch(
                    fields: fields,
                    limit: limit,
                    loadingMore: limit > Self.searchPageSize && hasRetainedCandidates
                )
            case .rescan:
                await rescan()
            case .seek:
                await seek()
            case .resolve(let candidate):
                await resolve(candidate)
            }
        }

        func apply(advance: Bool) async -> Bool {
            guard let item = selectedItem, let proposal = item.proposal, !item.cascadeRunning else {
                return false
            }
            isApplying = true
            errorMessage = nil
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
                let succeeded = await pollApply(
                    entityID: item.entityID,
                    progressID: progressID,
                    started: started
                )
                guard succeeded else {
                    isApplying = false
                    return false
                }
                if advance { selectNext() }
            } catch {
                errorMessage = error.localizedDescription
                isApplying = false
                return false
            }
            isApplying = false
            return true
        }

        func reject(advance: Bool) async -> Bool {
            guard let item = selectedItem else { return false }
            errorMessage = nil
            do {
                try await service.removeIdentifyItem(entityID: item.entityID)
                queue.removeAll { $0.entityID == item.entityID }
                if advance { selectNext() } else { selectedItemID = nil }
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
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

        func prepareBrowse(kind: EntityKind) {
            selectedKind = kind
            reconcileBrowseProvider(for: kind)
        }

        func queueBrowseItems(
            _ items: [EntityThumbnail],
            kind: EntityKind,
            providerID: String
        ) async -> EntityGridMutationResult {
            guard !items.isEmpty,
                RequestIdentifyProviderPreferencePolicy.identifyProviders(
                    providers,
                    entityKind: kind.rawValue,
                    defaultProviderIDs: defaultProviderIDs,
                    hidesNsfw: hidesNsfw
                ).contains(where: { $0.id == providerID })
            else {
                return EntityGridMutationResult(
                    failures: items.map {
                        EntityGridMutationFailure(
                            entityID: $0.id,
                            title: $0.title,
                            message: "Choose an available identify provider and try again."
                        )
                    }
                )
            }

            do {
                _ = try await service.startBulkIdentify(
                    provider: providerID,
                    entityIDs: items.map(\.id),
                    query: nil
                )
                await refreshQueue()
                return EntityGridMutationResult(succeededIDs: Set(items.map(\.id)))
            } catch {
                return EntityGridMutationResult(
                    failures: items.map {
                        EntityGridMutationFailure(
                            entityID: $0.id,
                            title: $0.title,
                            message: error.localizedDescription
                        )
                    }
                )
            }
        }

        func reviewAll() {
            select(reviewableIDs.first)
            loadSelectedEntityDetailInBackground()
        }

        func selectNext() {
            select(IdentifyNextFlow.next(after: selectedItemID, in: reviewableIDs))
            loadSelectedEntityDetailInBackground()
        }

        func selectPrevious() {
            select(IdentifyNextFlow.previous(before: selectedItemID, in: reviewableIDs))
            loadSelectedEntityDetailInBackground()
        }

        func returnToSearch() {
            activeCandidateID = nil
            showsSearchForProposal = true
        }

        func cancelPolling() {
            pollingToken = UUID()
        }

        func selectProvider(_ providerID: String) {
            rememberCurrentSearchValues()
            let candidates: [AdministrativePlugin]
            if let item = selectedItem {
                candidates = RequestIdentifyProviderPreferencePolicy.identifyProviders(
                    providers,
                    entityKind: item.entityKind.rawValue,
                    defaultProviderIDs: defaultProviderIDs,
                    hidesNsfw: hidesNsfw
                )
            } else {
                candidates = providers
            }
            let canonicalID =
                candidates.first {
                    $0.id.caseInsensitiveCompare(providerID) == .orderedSame
                }?.id ?? ""
            guard canonicalID != selectedProviderID else { return }
            selectedProviderID = canonicalID
            searchLimit = Self.searchPageSize
            retryOperation = nil
            restoreSearchValues()
            activeCandidateID = nil
            errorMessage = nil
        }

        func searchCandidates(
            for item: AdministrativeIdentifyQueueItem
        ) -> [AdministrativeEntitySearchCandidate] {
            let itemMatchesSelectedProvider =
                item.provider?.caseInsensitiveCompare(selectedProviderID) == .orderedSame
            if itemMatchesSelectedProvider, !item.candidates.isEmpty {
                return item.candidates
            }

            let retainedCandidates =
                retainedCandidatesBySearchContext[
                    searchValuesKey(entityID: item.entityID, providerID: selectedProviderID)
                ] ?? []
            let state = IdentifyQueueState(rawServerValue: item.state)
            if !itemMatchesSelectedProvider
                || isSearchBusy
                || errorMessage != nil
                || state == .queued
                || state == .searching
                || state == .error
            {
                return retainedCandidates
            }
            return []
        }

        func loadSelectedEntityDetail() async {
            guard let item = selectedItem,
                entityDetailsByID[item.entityID] == nil,
                entityDetailLoadingIDs.insert(item.entityID).inserted
            else { return }
            defer { entityDetailLoadingIDs.remove(item.entityID) }

            do {
                entityDetailsByID[item.entityID] = try await browser.detail(
                    entityID: item.entityID,
                    kind: item.entityKind
                )
            } catch is CancellationError {
                return
            } catch {
                // Queue content remains usable when the optional visual context
                // cannot be loaded.
            }
        }

        private func beginSearch(entityID: UUID, provider: String?, query: AdministrativeIdentifyQuery?) async {
            isSearching = true
            errorMessage = nil
            defer { isSearching = false }
            _ = await searchAndPoll(entityID: entityID, provider: provider, query: query)
        }

        private func searchAndPoll(entityID: UUID, provider: String?, query: AdministrativeIdentifyQuery?) async
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

        private func pollApply(
            entityID: UUID,
            progressID: UUID,
            started: Date
        ) async -> Bool {
            let token = UUID()
            pollingToken = token
            do {
                while true {
                    guard pollingToken == token else { return false }
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
                        if progress.state.lowercased() == "done" {
                            return true
                        }
                        errorMessage = progress.error ?? "Identification could not be applied."
                        return false
                    }
                    try await sleep(pollingPolicy.applyInterval(elapsed: elapsed))
                }
            } catch is CancellationError {
                return false
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        }

        private func receive(_ item: AdministrativeIdentifyQueueItem) {
            replace(item)
            if let providerID = item.provider, !providerID.isEmpty {
                let key = searchValuesKey(entityID: item.entityID, providerID: providerID)
                if !item.candidates.isEmpty {
                    retainedCandidatesBySearchContext[key] = item.candidates
                } else if IdentifyQueueState(rawServerValue: item.state) == .choice {
                    retainedCandidatesBySearchContext.removeValue(forKey: key)
                }
            }
            reviewSelection = item.proposal.map(MetadataReviewPolicy.seededSelection) ?? .init()
            if item.proposal != nil { showsSearchForProposal = false }
        }

        private func replace(_ item: AdministrativeIdentifyQueueItem) {
            if let index = queue.firstIndex(where: { $0.entityID == item.entityID }) {
                if queue[index] != item { queue[index] = item }
            } else {
                queue.insert(item, at: 0)
            }
        }

        private func receiveQueueRefresh(_ nextQueue: [AdministrativeIdentifyQueueItem]) {
            guard queue != nextQueue else { return }
            let previousProposal = selectedItem?.proposal
            let previousProposalID = previousProposal?.proposalID
            queue = nextQueue

            let validSelection = selectedQueueIDs.intersection(Set(nextQueue.map(\.entityID)))
            if selectedQueueIDs != validSelection { selectedQueueIDs = validSelection }

            guard let selectedItemID,
                let refreshedItem = nextQueue.first(where: { $0.entityID == selectedItemID })
            else {
                select(nextQueue.first?.entityID)
                return
            }

            if previousProposalID != refreshedItem.proposal?.proposalID {
                select(selectedItemID)
            } else {
                if let proposal = refreshedItem.proposal {
                    reviewSelection = MetadataReviewPolicy.mergingSeededDefaults(
                        from: previousProposal,
                        to: proposal,
                        into: reviewSelection
                    )
                }
                reconcileProvider()
            }
        }

        private func reconcileProvider() {
            reconcileProvider(preferConfiguredDefault: false)
        }

        private func reconcileProvider(preferConfiguredDefault: Bool) {
            guard let item = selectedItem else { return }
            let eligible = RequestIdentifyProviderPreferencePolicy.identifyProviders(
                providers,
                entityKind: item.entityKind.rawValue,
                defaultProviderIDs: defaultProviderIDs,
                hidesNsfw: hidesNsfw
            )
            let nextProviderID: String
            if preferConfiguredDefault {
                nextProviderID = RequestIdentifyProviderPreferencePolicy.resolvedProviderID(
                    in: eligible,
                    restoredProviderID: item.provider,
                    currentProviderID: nil
                )
            } else {
                nextProviderID = RequestIdentifyProviderPreferencePolicy.resolvedProviderID(
                    in: eligible,
                    restoredProviderID: selectedProviderID,
                    currentProviderID: item.provider
                )
            }
            if selectedProviderID != nextProviderID {
                rememberCurrentSearchValues()
                selectedProviderID = nextProviderID
            }
            restoreSearchValues()
        }

        private func reconcileBrowseProvider(for kind: EntityKind) {
            let eligible = RequestIdentifyProviderPreferencePolicy.identifyProviders(
                providers,
                entityKind: kind.rawValue,
                defaultProviderIDs: defaultProviderIDs,
                hidesNsfw: hidesNsfw
            )
            selectedProviderID = RequestIdentifyProviderPreferencePolicy.resolvedProviderID(
                in: eligible,
                restoredProviderID: selectedProviderID,
                currentProviderID: nil
            )
        }

        private func select(_ entityID: UUID?) {
            rememberCurrentSearchValues()
            selectedItemID = entityID
            let proposal = queue.first { $0.entityID == entityID }?.proposal
            reviewSelection = proposal.map(MetadataReviewPolicy.seededSelection) ?? .init()
            showsSearchForProposal = false
            searchLimit = queue.first { $0.entityID == entityID }?.query?.limit ?? Self.searchPageSize
            activeCandidateID = nil
            retryOperation = nil
            reconcileProvider(preferConfiguredDefault: true)
        }

        private func rememberCurrentSearchValues() {
            guard let item = selectedItem, !selectedProviderID.isEmpty else { return }
            searchValuesByEntityAndProvider[
                searchValuesKey(entityID: item.entityID, providerID: selectedProviderID)
            ] = searchValues
        }

        private func restoreSearchValues() {
            guard let item = selectedItem,
                let provider = providersForSelectedItem.first(where: {
                    $0.id.caseInsensitiveCompare(selectedProviderID) == .orderedSame
                })
            else {
                searchValues = [:]
                return
            }

            let key = searchValuesKey(entityID: item.entityID, providerID: provider.id)
            let restoredQueryValues: [String: String]
            if item.provider?.caseInsensitiveCompare(provider.id) == .orderedSame {
                restoredQueryValues = item.query?.fields ?? [:]
            } else {
                restoredQueryValues = [:]
            }
            let existing = searchValuesByEntityAndProvider[key] ?? restoredQueryValues
            let fields =
                PluginSearchFieldPolicy.searchSupport(
                    in: provider,
                    entityKind: item.entityKind.rawValue
                )?.search?.fields ?? []
            searchValues = PluginSearchFieldPolicy.seedValues(
                for: fields,
                existing: existing,
                title: item.title
            )
            searchValuesByEntityAndProvider[key] = searchValues
        }

        private func searchValuesKey(
            entityID: UUID,
            providerID: String
        ) -> String {
            "\(entityID.uuidString.lowercased())|\(providerID.lowercased())"
        }

        private func retainCandidates(
            for item: AdministrativeIdentifyQueueItem
        ) {
            let visibleCandidates = searchCandidates(for: item)
            guard !visibleCandidates.isEmpty, !selectedProviderID.isEmpty else { return }
            retainedCandidatesBySearchContext[
                searchValuesKey(entityID: item.entityID, providerID: selectedProviderID)
            ] = visibleCandidates
        }

        private func loadSelectedEntityDetailInBackground() {
            Task { await loadSelectedEntityDetail() }
        }

        private func loadDefaultProviderIDs() async -> [String: String]? {
            do {
                let response = try await service.settingValues(
                    keys: [RequestIdentifyProviderPreferencePolicy.settingKey]
                )
                return RequestIdentifyProviderPreferencePolicy.defaults(from: response)
            } catch {
                return nil
            }
        }

        private func loadProviders(kind: String?) async -> [AdministrativePlugin]? {
            do {
                return try await service.identifyProviders(kind: kind)
            } catch {
                return nil
            }
        }
    }
#endif
