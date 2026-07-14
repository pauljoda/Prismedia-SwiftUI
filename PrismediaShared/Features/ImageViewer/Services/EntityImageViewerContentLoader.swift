import Foundation

public actor EntityImageViewerContentLoader {
    private let detailLoader: any EntityDetailLoading
    private let sourceLoader: (any EntityImageSourceLoading)?
    private var retainedIDs: Set<UUID>
    private var preparationGeneration = 0
    private var detailCache: [UUID: EntityDetail]
    private var sourceCache: [UUID: Data] = [:]
    private var sourceCacheRecency: [UUID] = []
    private var sourceCacheByteCount = 0
    private let sourceCacheByteLimit: Int
    private var detailRequests: [UUID: (token: UUID, task: Task<EntityDetail, Error>)] = [:]
    private var sourceRequests: [UUID: (token: UUID, task: Task<Data, Error>)] = [:]
    private var sourceConsumerIDs: [UUID: Set<UUID>] = [:]

    public init(
        detailLoader: any EntityDetailLoading,
        sourceLoader: (any EntityImageSourceLoading)?,
        retainedItems: [EntityThumbnail],
        initialDetails: [EntityDetail] = [],
        sourceCacheByteLimit: Int = 64 * 1_024 * 1_024
    ) {
        self.detailLoader = detailLoader
        self.sourceLoader = sourceLoader
        self.sourceCacheByteLimit = max(0, sourceCacheByteLimit)
        retainedIDs = Set(retainedItems.map(\.id))
        detailCache = Dictionary(
            uniqueKeysWithValues: initialDetails.map { ($0.id, $0) }
        )
    }

    public func prepare(
        activeEntityID: UUID,
        sequence: EntityMediaSequence
    ) async {
        preparationGeneration &+= 1
        let generation = preparationGeneration
        let items = sequence.preloadItems(around: activeEntityID)
        retainOnly(items)

        for item in items {
            guard generation == preparationGeneration, !Task.isCancelled else { return }
            do {
                let detail = try await loadDetail(id: item.id)
                guard generation == preparationGeneration, !Task.isCancelled else { return }
                let projection = EntityImageMediaProjection(detail: detail)
                guard projection.sourcePath != nil, projection.mediaKind != .video else { continue }
                _ = try await loadSourceData(id: item.id)
            } catch is CancellationError {
                return
            } catch {
                continue
            }
        }
    }

    public func retain(_ items: [EntityThumbnail]) {
        retainOnly(items)
    }

    public func cancelSourceLoad(id: UUID) {
        sourceRequests[id]?.task.cancel()
        sourceRequests[id] = nil
        sourceConsumerIDs[id] = nil
    }

    public func cancelSourceLoad(id: UUID, consumerID: UUID) {
        releaseSourceConsumer(id: id, consumerID: consumerID, cancelIfUnused: true)
    }

    public func loadDetail(id: UUID) async throws -> EntityDetail {
        if let cached = detailCache[id] { return cached }
        let request = detailRequest(for: id)
        do {
            let detail = try await request.task.value
            if let cached = detailCache[id] { return cached }
            guard detailRequests[id]?.token == request.token else {
                throw CancellationError()
            }
            detailRequests[id] = nil
            if retainedIDs.contains(id) { detailCache[id] = detail }
            return detail
        } catch {
            if detailRequests[id]?.token == request.token {
                detailRequests[id] = nil
            }
            throw error
        }
    }

    public func loadSourceData(id: UUID) async throws -> Data {
        if let cached = sourceCache[id] {
            recordSourceAccess(id: id)
            return cached
        }
        let request = try sourceRequest(for: id)
        do {
            let data = try await request.task.value
            if let cached = sourceCache[id] { return cached }
            guard sourceRequests[id]?.token == request.token else {
                throw CancellationError()
            }
            sourceRequests[id] = nil
            if retainedIDs.contains(id) { cacheSourceData(data, id: id) }
            return data
        } catch {
            if sourceRequests[id]?.token == request.token {
                sourceRequests[id] = nil
            }
            throw error
        }
    }

    public func loadSourceData(id: UUID, consumerID: UUID) async throws -> Data {
        sourceConsumerIDs[id, default: []].insert(consumerID)
        defer {
            releaseSourceConsumer(id: id, consumerID: consumerID, cancelIfUnused: false)
        }
        return try await loadSourceData(id: id)
    }

    private func retainOnly(_ items: [EntityThumbnail]) {
        let nextIDs = Set(items.map(\.id))
        retainedIDs = nextIDs
        detailCache = detailCache.filter { nextIDs.contains($0.key) }
        let staleSourceCacheIDs = sourceCache.keys.filter { !nextIDs.contains($0) }
        for id in staleSourceCacheIDs {
            removeSourceData(id: id)
        }

        let staleDetailIDs = detailRequests.keys.filter { !nextIDs.contains($0) }
        for id in staleDetailIDs {
            detailRequests[id]?.task.cancel()
            detailRequests[id] = nil
        }
        let staleSourceIDs = sourceRequests.keys.filter { !nextIDs.contains($0) }
        for id in staleSourceIDs {
            sourceRequests[id]?.task.cancel()
            sourceRequests[id] = nil
            sourceConsumerIDs[id] = nil
        }
    }

    private func releaseSourceConsumer(
        id: UUID,
        consumerID: UUID,
        cancelIfUnused: Bool
    ) {
        sourceConsumerIDs[id]?.remove(consumerID)
        guard sourceConsumerIDs[id]?.isEmpty != false else { return }
        sourceConsumerIDs[id] = nil
        if cancelIfUnused {
            sourceRequests[id]?.task.cancel()
            sourceRequests[id] = nil
        }
    }

    private func cacheSourceData(_ data: Data, id: UUID) {
        removeSourceData(id: id)
        guard data.count <= sourceCacheByteLimit else { return }
        sourceCache[id] = data
        sourceCacheByteCount += data.count
        sourceCacheRecency.append(id)
        evictSourceDataToBudget()
    }

    private func recordSourceAccess(id: UUID) {
        sourceCacheRecency.removeAll { $0 == id }
        sourceCacheRecency.append(id)
    }

    private func evictSourceDataToBudget() {
        while sourceCacheByteCount > sourceCacheByteLimit,
            let leastRecentID = sourceCacheRecency.first
        {
            removeSourceData(id: leastRecentID)
        }
    }

    private func removeSourceData(id: UUID) {
        sourceCacheByteCount -= sourceCache.removeValue(forKey: id)?.count ?? 0
        sourceCacheRecency.removeAll { $0 == id }
    }

    private func detailRequest(
        for id: UUID
    ) -> (token: UUID, task: Task<EntityDetail, Error>) {
        if let request = detailRequests[id] { return request }
        let token = UUID()
        let loader = detailLoader
        let task = Task { try await loader.loadEntity(id: id) }
        let request = (token: token, task: task)
        detailRequests[id] = request
        return request
    }

    private func sourceRequest(
        for id: UUID
    ) throws -> (token: UUID, task: Task<Data, Error>) {
        if let request = sourceRequests[id] { return request }
        guard let sourceLoader else { throw URLError(.unsupportedURL) }
        let token = UUID()
        let task = Task { try await sourceLoader.loadEntitySourceData(id: id) }
        let request = (token: token, task: task)
        sourceRequests[id] = request
        return request
    }
}
