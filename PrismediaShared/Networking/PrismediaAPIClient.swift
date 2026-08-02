import Foundation

/// Client for the Prismedia user-auth API.
///
/// Construct unauthenticated for the public routes (health, setup-status, login,
/// first-run setup), then call `authenticated(with:)` once a session token exists.
/// Authenticated requests send `Authorization: Bearer <token>`; media URLs that a
/// native player fetches itself (AVPlayer, HLS) get the token as `?access_token=`.
/// Cover/thumbnail assets under `/assets/**` are public and need no token.
public struct PrismediaAPIClient: Sendable {
    private static let accessTokenQueryName = "access_token"

    public let serverURL: URL
    public let accessToken: String?
    public var allowsNsfwContent: Bool { nsfwPolicy.isAllowed }
    private let loader: HTTPDataLoading
    private let uploadLoader: HTTPUploadLoading
    private let nsfwPolicy: NsfwContentPolicy

    public init(
        serverURL: URL,
        accessToken: String? = nil,
        allowsNsfwContent: Bool = false,
        loader: HTTPDataLoading = URLSession.shared,
        uploadLoader: HTTPUploadLoading = URLSessionHTTPUploadLoader()
    ) {
        self.serverURL = serverURL
        self.accessToken = accessToken
        nsfwPolicy = NsfwContentPolicy(isAllowed: allowsNsfwContent)
        self.loader = loader
        self.uploadLoader = uploadLoader
    }

    private init(
        serverURL: URL,
        accessToken: String?,
        nsfwPolicy: NsfwContentPolicy,
        loader: HTTPDataLoading,
        uploadLoader: HTTPUploadLoading
    ) {
        self.serverURL = serverURL
        self.accessToken = accessToken
        self.nsfwPolicy = nsfwPolicy
        self.loader = loader
        self.uploadLoader = uploadLoader
    }

    public func authenticated(with accessToken: String) -> PrismediaAPIClient {
        PrismediaAPIClient(
            serverURL: serverURL,
            accessToken: accessToken,
            nsfwPolicy: nsfwPolicy,
            loader: loader,
            uploadLoader: uploadLoader
        )
    }

    public func allowingNsfwContent(_ allowsNsfwContent: Bool) -> PrismediaAPIClient {
        PrismediaAPIClient(
            serverURL: serverURL,
            accessToken: accessToken,
            allowsNsfwContent: allowsNsfwContent,
            loader: loader,
            uploadLoader: uploadLoader
        )
    }

    public func updateNsfwContentPreference(_ allowsNsfwContent: Bool) {
        nsfwPolicy.isAllowed = allowsNsfwContent
    }

    // MARK: - Public routes

    public func health() async throws -> HealthResponse {
        try await send(HealthResponse.self, path: "/api/health")
    }

    public func setupStatus() async throws -> SetupStatusResponse {
        try await send(SetupStatusResponse.self, path: "/api/auth/setup-status")
    }

    public func login(username: String, password: String, device: ClientDeviceInfo? = nil) async throws -> LoginResponse
    {
        try await send(
            LoginResponse.self,
            path: "/api/auth/login",
            method: "POST",
            body: LoginRequest(
                username: username,
                password: password,
                client: device?.client,
                deviceName: device?.deviceName,
                deviceId: device?.deviceID
            )
        )
    }

    public func completeFirstRunSetup(username: String, password: String, displayName: String?) async throws
        -> LoginResponse
    {
        try await send(
            LoginResponse.self,
            path: "/api/auth/setup",
            method: "POST",
            body: SetupRequest(username: username, password: password, displayName: displayName)
        )
    }

    // MARK: - Authenticated routes

    public func currentUser() async throws -> UserAccount {
        try await send(UserAccount.self, path: "/api/auth/me")
    }

    public func logout() async throws {
        try await sendExpectingNoContent(path: "/api/auth/logout", method: "POST")
    }

    public func listEntities(_ query: EntityListQuery, limit: Int = 48, search: String? = nil) async throws
        -> EntityListResponse
    {
        var query = query
        query.applyNsfwPreference(allowsNsfwContent: allowsNsfwContent)
        return try await send(
            EntityListResponse.self,
            path: query.path,
            queryItems: query.queryItems(limit: limit, search: search)
        )
    }

    public func listAllEntities(
        _ query: EntityListQuery,
        pageSize: Int = 1_000,
        search: String? = nil
    ) async throws -> [EntityThumbnail] {
        precondition(pageSize > 0, "An entity page size must be positive.")
        var items: [EntityThumbnail] = []
        var seenIDs = Set<UUID>()
        var visitedCursors = Set<String>()
        var cursor: String?

        while true {
            try Task.checkCancellation()
            var pageQuery = query
            pageQuery.cursor = cursor
            let response = try await listEntities(pageQuery, limit: pageSize, search: search)
            items += response.items.filter { seenIDs.insert($0.id).inserted }

            guard let nextCursor = response.nextCursor,
                visitedCursors.insert(nextCursor).inserted
            else { return items }
            cursor = nextCursor
        }
    }

    public func fetchEntity(id: UUID) async throws -> EntityDetail {
        try await send(
            EntityDetail.self,
            path: "/api/entities/\(id.uuidString.lowercased())",
            queryItems: [nsfwVisibilityQueryItem]
        )
    }

    public func deleteEntityFiles(id: UUID) async throws -> EntityDeleteResponse {
        try await send(
            EntityDeleteResponse.self,
            path: "/api/entities/\(id.uuidString.lowercased())",
            method: "DELETE",
            queryItems: [URLQueryItem(name: "deleteFiles", value: "true")]
        )
    }

    public func fetchEntityMonitorState(entityID: UUID) async throws -> EntityMonitorState {
        let states = try await fetchEntityMonitorStates(entityIDs: [entityID])
        guard let state = states.first(where: { $0.entityID == entityID }) else {
            throw PrismediaAPIError.invalidResponse
        }
        return state
    }

    public func fetchEntityMonitorStates(entityIDs: [UUID]) async throws -> [EntityMonitorState] {
        guard !entityIDs.isEmpty else { return [] }

        var seenIDs = Set<UUID>()
        let uniqueIDs = entityIDs.filter { seenIDs.insert($0).inserted }
        var states: [EntityMonitorState] = []

        for startIndex in stride(from: 0, to: uniqueIDs.count, by: 500) {
            try Task.checkCancellation()
            let endIndex = min(startIndex + 500, uniqueIDs.count)
            let batch = Array(uniqueIDs[startIndex ..< endIndex])
            let batchStates = try await send(
                [EntityMonitorState].self,
                path: "/api/monitors/states",
                method: "POST",
                body: EntityMonitorStateRequest(entityIds: batch)
            )
            states.append(contentsOf: batchStates)
        }

        return states
    }

    @discardableResult
    public func startEntityMonitor(entityID: UUID) async throws -> EntityMonitor {
        try await send(
            EntityMonitor.self,
            path: "/api/monitors/entity",
            method: "POST",
            body: EntityMonitorCreateRequest(entityId: entityID)
        )
    }

    public func pauseMonitor(id: UUID) async throws {
        try await sendExpectingNoContent(
            path: "/api/monitors/\(id.uuidString.lowercased())/pause",
            method: "POST"
        )
    }

    public func resumeMonitor(id: UUID) async throws {
        try await sendExpectingNoContent(
            path: "/api/monitors/\(id.uuidString.lowercased())/resume",
            method: "POST"
        )
    }

    public func searchAcquisitionAgain(id: UUID) async throws {
        _ = try await researchRequestActivityAcquisition(id: id)
    }

    public func unmonitor(id: UUID) async throws -> EntityMonitorStopResponse {
        try await send(
            EntityMonitorStopResponse.self,
            path: "/api/monitors/\(id.uuidString.lowercased())",
            method: "DELETE"
        )
    }

    public func syncEntityContainer(entityID: UUID) async throws {
        try await sendExpectingNoContent(
            path: "/api/requests/sync-container",
            method: "POST",
            body: EntityAcquisitionEntityRequest(entityId: entityID)
        )
    }

    public func commitMissingChildren(
        entityID: UUID
    ) async throws -> EntityMissingChildrenSearchResponse {
        try await send(
            EntityMissingChildrenSearchResponse.self,
            path: "/api/requests/commit-missing-children",
            method: "POST",
            body: EntityAcquisitionEntityRequest(entityId: entityID)
        )
    }

    public func updateEntityRating(id: UUID, value: Int?) async throws -> EntityDetail {
        try await send(
            EntityDetail.self,
            path: "/api/entities/\(id.uuidString.lowercased())/rating",
            method: "PATCH",
            body: EntityRatingUpdateRequest(value: value)
        )
    }

    public func updateEntityFlags(
        id: UUID,
        isFavorite: Bool?,
        isNsfw: Bool?,
        isOrganized: Bool?
    ) async throws -> EntityDetail {
        try await send(
            EntityDetail.self,
            path: "/api/entities/\(id.uuidString.lowercased())/flags",
            method: "PATCH",
            body: EntityFlagsUpdateRequest(
                isFavorite: isFavorite,
                isNsfw: isNsfw,
                isOrganized: isOrganized
            )
        )
    }

    public func updateEntityMetadata(
        id: UUID,
        kind: EntityKind,
        request: EntityDetailMetadataUpdateRequest
    ) async throws -> EntityDetail {
        try await send(
            EntityDetail.self,
            path: "/api/entities/\(kind.rawValue)/\(id.uuidString.lowercased())",
            method: "PATCH",
            body: request
        )
    }

    public func updateEntityProgress(
        id: UUID,
        request: EntityProgressUpdateRequest
    ) async throws -> EntityDetail {
        try await send(
            EntityDetail.self,
            path: "/api/entities/\(id.uuidString.lowercased())/progress",
            method: "PATCH",
            body: request
        )
    }

    public func fetchEntityThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
        guard !ids.isEmpty else { return [] }
        let response = try await send(
            EntityThumbnailBatchResponse.self,
            path: "/api/entities/thumbnails",
            method: "POST",
            queryItems: [nsfwVisibilityQueryItem],
            body: EntityThumbnailBatchRequest(ids: ids)
        )
        return response.items
    }

    /// Resolves direct child thumbnails for several Entity parents without hydrating one full
    /// detail document per parent. The API accepts at most 250 unique parents per request.
    public func fetchEntityChildren(parentIDs: [UUID]) async throws -> [EntityChildrenBatchGroup] {
        var seenIDs = Set<UUID>()
        let uniqueIDs = parentIDs.filter { seenIDs.insert($0).inserted }
        guard !uniqueIDs.isEmpty else { return [] }

        var groups: [EntityChildrenBatchGroup] = []
        for start in stride(from: 0, to: uniqueIDs.count, by: 250) {
            try Task.checkCancellation()
            let end = min(start + 250, uniqueIDs.count)
            let response = try await send(
                EntityChildrenBatchResponse.self,
                path: "/api/entities/children",
                method: "POST",
                queryItems: [nsfwVisibilityQueryItem],
                body: EntityChildrenBatchRequest(parentIds: Array(uniqueIDs[start ..< end]))
            )
            groups += response.groups
        }

        return groups
    }

    public func listCollections() async throws -> EntityListResponse {
        try await listEntities(
            EntityListQuery(path: "/api/collections"),
            limit: 250
        )
    }

    public func fetchCollectionItems(collectionID: UUID) async throws -> [EntityThumbnail] {
        let response = try await send(
            CollectionItemsResponse.self,
            path: "/api/collections/\(collectionID.uuidString.lowercased())/items",
            queryItems: [nsfwVisibilityQueryItem]
        )
        return response.entities
    }

    public func fetchCollectionMemberIDs(
        collectionID: UUID
    ) async throws -> [UUID: UUID] {
        let response = try await send(
            CollectionItemsResponse.self,
            path: "/api/collections/\(collectionID.uuidString.lowercased())/items",
            queryItems: [nsfwVisibilityQueryItem]
        )
        return response.items.reduce(into: [:]) { result, item in
            guard let itemID = item.id else { return }
            result[item.entityID ?? item.entity.id] = itemID
        }
    }

    public func fetchConsumptionStatistics(
        _ query: ConsumptionStatisticsQuery
    ) async throws -> ConsumptionStatisticsResponse {
        var query = query
        query.hideNsfw = !allowsNsfwContent
        return try await send(
            ConsumptionStatisticsResponse.self,
            path: "/api/consumption/statistics",
            queryItems: query.queryItems
        )
    }

    private var nsfwVisibilityQueryItem: URLQueryItem {
        URLQueryItem(name: "hideNsfw", value: allowsNsfwContent ? "false" : "true")
    }

    @discardableResult
    public func addToCollection(
        collectionID: UUID,
        items: [CollectionEntityReference]
    ) async throws -> Int {
        let response = try await send(
            CollectionItemMutationResponse.self,
            path: "/api/collections/\(collectionID.uuidString.lowercased())/items",
            method: "POST",
            body: CollectionAddItemsRequest(items: items)
        )
        return response.count
    }

    public func removeCollectionItem(
        collectionID: UUID,
        itemID: UUID
    ) async throws -> Bool {
        let response = try await send(
            CollectionItemMutationResponse.self,
            path: "/api/collections/\(collectionID.uuidString.lowercased())/items/remove",
            method: "POST",
            body: CollectionRemoveItemsRequest(itemIds: [itemID])
        )
        return response.count == 1
    }

    public func removeWanted(entityID: UUID) async throws -> WantedRemovalResponse {
        try await send(
            WantedRemovalResponse.self,
            path: "/api/requests/remove-wanted",
            method: "POST",
            body: WantedRemovalRequest(entityIds: [entityID])
        )
    }

    public func audioStreamURL(for trackID: UUID) -> URL? {
        tokenAuthenticatedURL(
            for: "/api/audio-stream/\(trackID.uuidString.lowercased())"
        )
    }

    public func recordEntityConsumptionEvent(
        id: UUID,
        kind: ConsumptionEventKind,
        positionSeconds: Double?,
        durationSeconds: Double?,
        sessionID: String? = nil
    ) async throws {
        _ = try await send(
            EntityThumbnail.self,
            path: "/api/entities/\(id.uuidString.lowercased())/consumption/events",
            method: "POST",
            body: EntityConsumptionEventCreateRequest(
                kind: kind,
                occurredAt: nil,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                sessionID: sessionID
            )
        )
    }

    public func updateEntityConsumption(
        id: UUID,
        positionSeconds: Double?,
        activitySeconds: Double? = nil,
        completed: Bool? = nil
    ) async throws {
        _ = try await send(
            EntityThumbnail.self,
            path: "/api/entities/\(id.uuidString.lowercased())/consumption",
            method: "PATCH",
            body: EntityConsumptionUpdateRequest(
                positionSeconds: positionSeconds.map { max(0, $0.isFinite ? $0 : 0) },
                activitySeconds: activitySeconds.flatMap {
                    $0.isFinite && $0 > 0 ? min($0, 60) : nil
                },
                completed: completed,
                utcOffsetMinutes: TimeZone.current.secondsFromGMT() / 60
            )
        )
    }

    public func reportVideoPlayback(
        _ event: VideoPlaybackEvent,
        report: VideoPlaybackReport
    ) async throws {
        let path =
            switch event {
            case .started: "/api/playback/sessions/start"
            case .progress: "/api/playback/sessions/progress"
            case .stopped: "/api/playback/sessions/stop"
            }
        try await sendExpectingNoContent(path: path, method: "POST", body: report)
    }

    public func negotiateVideoPlayback(
        videoID: UUID,
        forceTranscode: Bool = false
    ) async throws -> VideoPlaybackPlan {
        try await negotiateVideoPlayback(
            videoID: videoID,
            mode: forceTranscode ? .transcode : .automatic,
            audioStreamIndex: nil,
            preferredEngine: .automatic
        )
    }

    public func negotiateVideoPlayback(
        videoID: UUID,
        forceTranscode: Bool,
        audioStreamIndex: Int? = nil
    ) async throws -> VideoPlaybackPlan {
        try await negotiateVideoPlayback(
            videoID: videoID,
            mode: forceTranscode ? .transcode : .automatic,
            audioStreamIndex: audioStreamIndex,
            preferredEngine: .automatic
        )
    }

    public func negotiateVideoPlayback(
        videoID: UUID,
        mode: VideoPlaybackNegotiationMode,
        audioStreamIndex: Int? = nil
    ) async throws -> VideoPlaybackPlan {
        try await negotiateVideoPlayback(
            videoID: videoID,
            mode: mode,
            audioStreamIndex: audioStreamIndex,
            preferredEngine: .automatic
        )
    }

    public func negotiateVideoPlayback(
        videoID: UUID,
        mode: VideoPlaybackNegotiationMode,
        audioStreamIndex: Int? = nil,
        preferredEngine: VideoPlaybackEngine
    ) async throws -> VideoPlaybackPlan {
        let response = try await send(
            VideoPlaybackPlanResponse.self,
            path: "/api/playback/videos/\(videoID.uuidString.lowercased())/plan",
            method: "POST",
            body: VideoPlaybackPlanRequest(
                mode: mode,
                audioStreamIndex: audioStreamIndex,
                preferredEngine: preferredEngine
            )
        )
        let source = response.source
        let delivery = source.method
        guard let url = authenticatedMediaURL(for: source.url) else {
            throw VideoPlaybackError.noPlayableSource
        }
        let sourceVideo = source.streams.first {
            $0.type.caseInsensitiveCompare(PrismediaContractCodes.StreamKind.video) == .orderedSame
        }
        let sourceAudioStreams = source.streams.filter {
            $0.type.caseInsensitiveCompare(PrismediaContractCodes.StreamKind.audio) == .orderedSame
        }
        if mode == .automatic,
            audioStreamIndex == nil,
            preferredEngine == .automatic,
            delivery == .direct,
            let nativeAudioStreamIndex = VideoNativeAudioStreamPolicy.preferredStreamIndex(
                container: source.container,
                streams: sourceAudioStreams
            )
        {
            return try await negotiateVideoPlayback(
                videoID: videoID,
                mode: .directStream,
                audioStreamIndex: nativeAudioStreamIndex,
                preferredEngine: .native
            )
        }
        let sourceAudio = sourceAudioStreams.first(where: \.isDefault) ?? sourceAudioStreams.first
        let renderer = source.playbackRenderer(
            delivery: delivery,
            preferredEngine: preferredEngine
        )
        return VideoPlaybackPlan(
            videoID: videoID,
            url: url,
            delivery: delivery,
            sessionID: response.sessionID,
            durationSeconds: source.durationSeconds ?? 0,
            badges: source.playbackBadges(delivery: delivery),
            audioStreams: source.playbackAudioStreams,
            httpHeaders:
                isSameOrigin(url)
                ? accessToken.map { ["Authorization": "Bearer \($0)"] } ?? [:]
                : [:],
            diagnostics: VideoPlaybackDiagnostics(
                sourceContainer: source.container,
                sourceVideoCodec: sourceVideo?.codec,
                sourceVideoCodecTag: nil,
                sourceAudioCodec: sourceAudio?.codec,
                outputVideoCodec: source.transcoding?.videoCodec ?? sourceVideo?.codec,
                outputAudioCodec: source.transcoding?.audioCodec ?? sourceAudio?.codec,
                transcodeReasons: []
            ),
            displayMetadata: source.playbackDisplayMetadata(delivery: delivery),
            requiresNativePlayabilityCheck: delivery == .direct && renderer == .native,
            renderer: renderer
        )
    }

    public func authenticatedMediaURL(for path: String) -> URL? {
        guard let url = try? url(path: path) else { return nil }
        let existingNames = Set(
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.map { $0.name.lowercased() } ?? [])
        if existingNames.contains(Self.accessTokenQueryName) {
            return url
        }
        return tokenAuthenticatedURL(for: path)
    }

    public func mediaData(for path: String) async throws -> Data {
        let data = try await perform(path: path, method: "GET", queryItems: [], body: Optional<LoginRequest>.none)
        return data
    }

    public func entitySourceData(id: UUID) async throws -> Data {
        try await mediaData(for: "/api/entities/\(id.uuidString.lowercased())/files/source")
    }

    // MARK: - URLs

    /// Resolves a server-relative asset path (covers, thumbnails) against the
    /// server URL. `/assets/**` is served before the auth middleware, so no
    /// token is attached.
    public func assetURL(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return try? url(path: path)
    }

    /// Resolves a stream path and appends the session token as `access_token`, for
    /// players that cannot send an Authorization header.
    public func tokenAuthenticatedURL(for path: String) -> URL? {
        guard let accessToken else { return nil }
        guard let resolvedURL = try? url(path: path) else { return nil }
        guard isSameOrigin(resolvedURL) else { return resolvedURL }
        return try? url(
            path: path,
            queryItems: [URLQueryItem(name: Self.accessTokenQueryName, value: accessToken)]
        )
    }

    // MARK: - Request plumbing

    public func url(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = try components(for: path)
        var mergedItems = components.queryItems ?? []
        mergedItems.append(contentsOf: queryItems)
        components.queryItems = mergedItems.isEmpty ? nil : mergedItems

        guard let url = components.url else {
            throw PrismediaAPIError.invalidURL(path)
        }

        return url
    }

    private func components(for path: String) throws -> URLComponents {
        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            guard let components = URLComponents(url: absoluteURL, resolvingAgainstBaseURL: false) else {
                throw PrismediaAPIError.invalidURL(path)
            }
            return components
        }

        guard var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false) else {
            throw PrismediaAPIError.invalidURL(path)
        }

        let relative = URLComponents(string: path)
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let relativePath = (relative?.path ?? path).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let joinedPath = [basePath, relativePath]
            .filter { !$0.isEmpty }
            .joined(separator: "/")

        components.path = joinedPath.isEmpty ? "" : "/\(joinedPath)"
        components.queryItems = relative?.queryItems
        return components
    }

    private func request(path: String, method: String, queryItems: [URLQueryItem], body: (some Encodable)?) throws
        -> URLRequest
    {
        var request = URLRequest(url: try url(path: path, queryItems: queryItems))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if method == "GET" {
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }

        if let accessToken, let requestURL = request.url, isSameOrigin(requestURL) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try PrismediaJSON.encoder().encode(body)
        }

        return request
    }

    private func isSameOrigin(_ url: URL) -> Bool {
        guard
            url.scheme?.lowercased() == serverURL.scheme?.lowercased(),
            url.host?.lowercased() == serverURL.host?.lowercased()
        else { return false }
        return effectivePort(of: url) == effectivePort(of: serverURL)
    }

    private func effectivePort(of url: URL) -> Int? {
        if let port = url.port { return port }
        switch url.scheme?.lowercased() {
        case "http": return 80
        case "https": return 443
        default: return nil
        }
    }

    func send<T: Decodable>(
        _ type: T.Type,
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: (some Encodable)? = Optional<LoginRequest>.none
    ) async throws -> T {
        let data = try await perform(path: path, method: method, queryItems: queryItems, body: body)

        do {
            return try PrismediaJSON.decoder().decode(T.self, from: data)
        } catch {
            throw PrismediaAPIError.decoding(error)
        }
    }

    func sendExpectingNoContent(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: (some Encodable)? = Optional<LoginRequest>.none
    ) async throws {
        _ = try await perform(path: path, method: method, queryItems: queryItems, body: body)
    }

    func sendMultipart<T: Decodable>(
        _ type: T.Type,
        path: String,
        fieldName: String,
        fileName: String,
        contentType: String,
        data: Data
    ) async throws -> T {
        let boundary = "PrismediaBoundary-\(UUID().uuidString)"
        let safeFileName =
            fileName
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "\r", with: "_")
            .replacingOccurrences(of: "\n", with: "_")
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(
            Data(
                "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(safeFileName)\"\r\n".utf8
            )
        )
        body.append(Data("Content-Type: \(contentType)\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        var request = URLRequest(url: try url(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        if let accessToken, let requestURL = request.url, isSameOrigin(requestURL) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (responseData, response) = try await loader.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PrismediaAPIError.invalidResponse
        }
        if 300..<400 ~= httpResponse.statusCode {
            let location = httpResponse.value(forHTTPHeaderField: "Location").flatMap(URL.init(string:))
            throw PrismediaAPIError.redirectedToSignIn(location)
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let problem = try? PrismediaJSON.decoder().decode(APIProblem.self, from: responseData)
            throw PrismediaAPIError.httpStatus(httpResponse.statusCode, problem)
        }
        do {
            return try PrismediaJSON.decoder().decode(type, from: responseData)
        } catch {
            throw PrismediaAPIError.decoding(error)
        }
    }

    func sendMultipartFiles<T: Decodable>(
        _ type: T.Type,
        path: String,
        files: [HTTPMultipartUploadFile],
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> T {
        let body = HTTPMultipartUploadBody(files: files)
        var request = URLRequest(url: try url(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(body.boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(String(body.contentLength), forHTTPHeaderField: "Content-Length")
        if let accessToken, let requestURL = request.url, isSameOrigin(requestURL) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let accessedURLs = files.compactMap { file -> URL? in
            file.sourceURL.startAccessingSecurityScopedResource() ? file.sourceURL : nil
        }
        defer {
            for url in accessedURLs { url.stopAccessingSecurityScopedResource() }
        }

        let (responseData, response) = try await uploadLoader.upload(
            for: request,
            body: body,
            progress: progress
        )
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PrismediaAPIError.invalidResponse
        }
        if 300..<400 ~= httpResponse.statusCode {
            let location = httpResponse.value(forHTTPHeaderField: "Location").flatMap(URL.init(string:))
            throw PrismediaAPIError.redirectedToSignIn(location)
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let problem = try? PrismediaJSON.decoder().decode(APIProblem.self, from: responseData)
            throw PrismediaAPIError.httpStatus(httpResponse.statusCode, problem)
        }
        do {
            return try PrismediaJSON.decoder().decode(type, from: responseData)
        } catch {
            throw PrismediaAPIError.decoding(error)
        }
    }

    func sendRawRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await loader.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PrismediaAPIError.invalidResponse
        }
        if 300..<400 ~= httpResponse.statusCode {
            let location = httpResponse.value(forHTTPHeaderField: "Location").flatMap(URL.init(string:))
            throw PrismediaAPIError.redirectedToSignIn(location)
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let problem = try? PrismediaJSON.decoder().decode(APIProblem.self, from: data)
            throw PrismediaAPIError.httpStatus(httpResponse.statusCode, problem)
        }
        return data
    }

    private func perform(
        path: String,
        method: String,
        queryItems: [URLQueryItem],
        body: (some Encodable)?
    ) async throws -> Data {
        let request = try request(path: path, method: method, queryItems: queryItems, body: body)
        let (data, response) = try await loader.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PrismediaAPIError.invalidResponse
        }

        if 300..<400 ~= httpResponse.statusCode {
            let location = httpResponse.value(forHTTPHeaderField: "Location").flatMap(URL.init(string:))
            throw PrismediaAPIError.redirectedToSignIn(location)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let problem = try? PrismediaJSON.decoder().decode(APIProblem.self, from: data)
            throw PrismediaAPIError.httpStatus(httpResponse.statusCode, problem)
        }

        return data
    }

    private final class NsfwContentPolicy: @unchecked Sendable {
        private let lock = NSLock()
        private var storedIsAllowed: Bool

        init(isAllowed: Bool) {
            storedIsAllowed = isAllowed
        }

        var isAllowed: Bool {
            get { lock.withLock { storedIsAllowed } }
            set { lock.withLock { storedIsAllowed = newValue } }
        }
    }
}

extension PrismediaAPIClient: MusicPlaybackServicing {
    public func artworkURL(for path: String?) -> URL? {
        assetURL(for: path)
    }

    public func reportEntityProgress(
        id: UUID,
        request: EntityProgressUpdateRequest
    ) async throws {
        _ = try await updateEntityProgress(id: id, request: request)
    }
}
