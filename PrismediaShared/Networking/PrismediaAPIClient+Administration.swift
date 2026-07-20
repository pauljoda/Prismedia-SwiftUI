import Foundation

extension PrismediaAPIClient {
    public func listAdministrativeFileRoots() async throws -> [AdministrativeFileRoot] {
        try await send(
            AdministrativeFileRootsResponse.self,
            path: "/api/files/roots",
            queryItems: [administrativeNsfwVisibilityQueryItem]
        ).roots
    }

    public func listAdministrativeFileChildren(rootID: UUID, path: String) async throws
        -> AdministrativeFileChildrenResponse
    {
        try await send(
            AdministrativeFileChildrenResponse.self,
            path: "/api/files/children",
            queryItems: [
                URLQueryItem(name: "rootId", value: rootID.uuidString.lowercased()),
                URLQueryItem(name: "path", value: path),
                administrativeNsfwVisibilityQueryItem,
            ]
        )
    }

    private var administrativeNsfwVisibilityQueryItem: URLQueryItem {
        URLQueryItem(name: "hideNsfw", value: allowsNsfwContent ? "false" : "true")
    }

    public func rescanAdministrativeFiles(rootID: UUID, path: String?) async throws
        -> AdministrativeFileOperationResponse
    {
        try await send(
            AdministrativeFileOperationResponse.self,
            path: "/api/files/rescan",
            method: "POST",
            body: AdministrativeFileRescanRequest(rootID: rootID, path: path)
        )
    }

    public func listAdministrativeIdentifyQueue(includeCompleted: Bool = false) async throws
        -> [AdministrativeIdentifyQueueItem]
    {
        try await send(
            [AdministrativeIdentifyQueueItem].self,
            path: "/api/identify/queue",
            queryItems: [
                URLQueryItem(name: "includeCompleted", value: includeCompleted ? "true" : "false"),
                administrativeNsfwVisibilityQueryItem,
            ]
        )
    }

    public func listAdministrativeIdentifyProviders(kind: String? = nil) async throws -> [AdministrativePlugin] {
        try await send(
            [AdministrativePlugin].self,
            path: "/api/identify/providers",
            queryItems: kind.map { [URLQueryItem(name: "kind", value: $0)] } ?? []
        )
    }

    public func addAdministrativeIdentifyQueueItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
        try await send(
            AdministrativeIdentifyQueueItem.self,
            path: administrativeIdentifyQueueEntityPath(entityID),
            method: "POST"
        )
    }

    public func getAdministrativeIdentifyQueueItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
        try await send(
            AdministrativeIdentifyQueueItem.self,
            path: administrativeIdentifyQueueEntityPath(entityID)
        )
    }

    public func searchAdministrativeIdentifyQueueItem(
        entityID: UUID,
        provider: String?,
        query: AdministrativeIdentifyQuery?
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await send(
            AdministrativeIdentifyQueueItem.self,
            path: "\(administrativeIdentifyQueueEntityPath(entityID))/search",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: AdministrativeIdentifyQueueSearchRequest(provider: provider, query: query)
        )
    }

    public func resolveAdministrativeIdentifyQueueCandidate(
        entityID: UUID,
        provider: String,
        candidate: AdministrativeEntitySearchCandidate
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await send(
            AdministrativeIdentifyQueueItem.self,
            path: "\(administrativeIdentifyQueueEntityPath(entityID))/candidate",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: AdministrativeIdentifyQueueCandidateRequest(provider: provider, candidate: candidate)
        )
    }

    public func applyAdministrativeIdentifyQueueItem(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal?,
        selectedFields: [String],
        selectedImages: [String: String?]?,
        progressID: UUID?
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await send(
            AdministrativeIdentifyQueueItem.self,
            path: "\(administrativeIdentifyQueueEntityPath(entityID))/apply",
            method: "POST",
            body: AdministrativeApplyIdentifyQueueItemRequest(
                proposal: proposal,
                selectedFields: selectedFields,
                selectedImages: selectedImages,
                progressID: progressID
            )
        )
    }

    public func saveAdministrativeIdentifyQueueProposal(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await send(
            AdministrativeIdentifyQueueItem.self,
            path: "\(administrativeIdentifyQueueEntityPath(entityID))/proposal",
            method: "PUT",
            body: AdministrativeSaveIdentifyQueueProposalRequest(proposal: proposal)
        )
    }

    public func administrativeIdentifyApplyProgress(
        entityID: UUID,
        progressID: UUID
    ) async throws -> AdministrativeIdentifyApplyProgress {
        try await send(
            AdministrativeIdentifyApplyProgress.self,
            path:
                "\(administrativeIdentifyQueueEntityPath(entityID))/apply-progress/\(progressID.uuidString.lowercased())"
        )
    }

    public func removeAdministrativeIdentifyQueueItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
        try await send(
            AdministrativeIdentifyQueueItem.self,
            path: administrativeIdentifyQueueEntityPath(entityID),
            method: "DELETE"
        )
    }

    public func identifyAdministrativeEntity(
        entityID: UUID,
        provider: String,
        query: AdministrativeIdentifyQuery?,
        parentExternalIDs: [String: String]?
    ) async throws -> AdministrativeEntityMetadataProposal {
        try await send(
            AdministrativeEntityMetadataProposal.self,
            path: "/api/identify/entities/\(entityID.uuidString.lowercased())",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: AdministrativeIdentifyEntityRequest(
                provider: provider,
                query: query,
                parentExternalIDs: parentExternalIDs
            )
        )
    }

    public func applyAdministrativeIdentifyProposal(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal,
        selectedFields: [String],
        selectedImages: [String: String?]?
    ) async throws {
        try await sendExpectingNoContent(
            path: "/api/identify/entities/\(entityID.uuidString.lowercased())/apply",
            method: "POST",
            body: AdministrativeApplyIdentifyProposalRequest(
                proposal: proposal,
                selectedFields: selectedFields,
                selectedImages: selectedImages
            )
        )
    }

    public func startAdministrativeBulkIdentify(
        provider: String?,
        entityIDs: [UUID],
        query: AdministrativeIdentifyQuery?
    ) async throws -> AdministrativeIdentifyBulkAcceptedResponse {
        try await send(
            AdministrativeIdentifyBulkAcceptedResponse.self,
            path: "/api/identify/bulk",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: AdministrativeIdentifyBulkStartRequest(provider: provider, entityIDs: entityIDs, query: query)
        )
    }

    public func listAdministrativePlugins() async throws -> [AdministrativePlugin] {
        try await send([AdministrativePlugin].self, path: "/api/plugins/")
    }

    public func updateAdministrativePlugin(id: String) async throws -> AdministrativePlugin {
        let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return try await send(
            AdministrativePlugin.self,
            path: "/api/plugins/\(encodedID)/update",
            method: "POST"
        )
    }

    public func searchAdministrativeRequests(
        kind: String,
        pluginID: String,
        fields: [String: String],
        limit: Int? = nil
    ) async throws -> AdministrativeRequestSearchResponse {
        try await send(
            AdministrativeRequestSearchResponse.self,
            path: "/api/requests/search",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: AdministrativeRequestSearchRequest(kind: kind, pluginID: pluginID, fields: fields, limit: limit)
        )
    }

    public func reviewAdministrativeRequest(
        kind: String,
        pluginID: String,
        externalIdentity: AdministrativeExternalIdentity
    ) async throws -> AdministrativeRequestReviewResponse {
        try await send(
            AdministrativeRequestReviewResponse.self,
            path: "/api/requests/review",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: AdministrativeRequestReviewRequest(
                kind: kind,
                pluginID: pluginID,
                externalIdentity: externalIdentity
            )
        )
    }

    public func reviewAdministrativeEntityRequest(
        entityID: UUID,
        kind: String
    ) async throws -> AdministrativeRequestReviewResponse {
        try await send(
            AdministrativeRequestReviewResponse.self,
            path: "/api/requests/review-entity",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: AdministrativeRequestEntityReviewRequest(entityID: entityID, kind: kind)
        )
    }

    public func commitAdministrativeReviewedRequest(
        _ request: AdministrativeReviewedRequestCommitRequest
    ) async throws -> AdministrativeRequestCommitResponse {
        try await send(
            AdministrativeRequestCommitResponse.self,
            path: "/api/requests/commit-reviewed",
            method: "POST",
            queryItems: [administrativeNsfwVisibilityQueryItem],
            body: request
        )
    }

    public func listAdministrativeLibraryRoots() async throws -> [AdministrativeLibraryRoot] {
        let roots = try await send([AdministrativeLibraryRoot].self, path: "/api/libraries")
        return allowsNsfwContent ? roots : roots.filter { !$0.isNsfw }
    }

    public func listAdministrativeAcquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile] {
        try await send([AdministrativeAcquisitionProfile].self, path: "/api/acquisitions/profiles")
    }

    public func listAdministrativeJobs() async throws -> AdministrativeJobListResponse {
        try await send(AdministrativeJobListResponse.self, path: "/api/jobs/")
    }

    public func createAdministrativeJob(type: String) async throws -> AdministrativeJobCreateResponse {
        let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? type
        return try await send(
            AdministrativeJobCreateResponse.self,
            path: "/api/jobs/\(encodedType)",
            method: "POST"
        )
    }

    public func cancelAdministrativeJob(id: UUID) async throws -> AdministrativeCountResponse {
        try await send(
            AdministrativeCountResponse.self,
            path: "/api/jobs/\(id.uuidString.lowercased())",
            method: "DELETE"
        )
    }

    public func cancelAdministrativeJobs(type: String? = nil) async throws -> AdministrativeCountResponse {
        try await send(
            AdministrativeCountResponse.self,
            path: "/api/jobs/",
            method: "DELETE",
            queryItems: type.map { [URLQueryItem(name: "type", value: $0)] } ?? []
        )
    }

    public func clearAdministrativeJobFailures(type: String? = nil) async throws -> AdministrativeCountResponse {
        try await send(
            AdministrativeCountResponse.self,
            path: "/api/jobs/failures/clear",
            method: "POST",
            queryItems: type.map { [URLQueryItem(name: "type", value: $0)] } ?? []
        )
    }

    public func rebuildAdministrativePreviews() async throws -> AdministrativeBulkJobResponse {
        try await send(
            AdministrativeBulkJobResponse.self,
            path: "/api/jobs/rebuild-previews",
            method: "POST"
        )
    }

    public func loadAdministrativeSettings() async throws -> AdministrativeSettingsCatalog {
        try await send(AdministrativeSettingsCatalog.self, path: "/api/settings/")
    }

    public func updateAdministrativeSetting(key: String, value: AdministrativeJSONValue) async throws
        -> AdministrativeSetting
    {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        return try await send(
            AdministrativeSetting.self,
            path: "/api/settings/\(encodedKey)",
            method: "PATCH",
            body: AdministrativeSettingUpdateRequest(value: value)
        )
    }

    public func administrativeTranscodeCacheStatus() async throws -> AdministrativeTranscodeCacheStatus {
        try await send(AdministrativeTranscodeCacheStatus.self, path: "/api/settings/transcode-cache")
    }

    public func clearAdministrativeTranscodeCache() async throws -> AdministrativeTranscodeCacheStatus {
        try await send(
            AdministrativeTranscodeCacheStatus.self,
            path: "/api/settings/transcode-cache/clear",
            method: "POST"
        )
    }

    public func createAdministrativeDatabaseBackup() async throws -> AdministrativeDatabaseBackup {
        try await send(
            AdministrativeDatabaseBackup.self,
            path: "/api/settings/database-backups/now",
            method: "POST"
        )
    }

    private func administrativeIdentifyQueueEntityPath(_ entityID: UUID) -> String {
        "/api/identify/queue/entities/\(entityID.uuidString.lowercased())"
    }
}
