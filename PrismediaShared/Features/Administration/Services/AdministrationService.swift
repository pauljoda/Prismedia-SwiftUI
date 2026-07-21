import Foundation

public struct AdministrationService: AdministrationServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func fileRoots() async throws -> [AdministrativeFileRoot] { try await client.listAdministrativeFileRoots() }
    public func fileChildren(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse {
        try await client.listAdministrativeFileChildren(rootID: rootID, path: path)
    }
    public func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse {
        try await client.rescanAdministrativeFiles(rootID: rootID, path: path)
    }
    public func identifyQueue() async throws -> [AdministrativeIdentifyQueueItem] {
        try await client.listAdministrativeIdentifyQueue()
    }
    public func identifyProviders(kind: String?) async throws -> [AdministrativePlugin] {
        try await client.listAdministrativeIdentifyProviders(kind: kind)
    }
    public func identifyQueueItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
        try await client.getAdministrativeIdentifyQueueItem(entityID: entityID)
    }
    public func addIdentifyItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
        try await client.addAdministrativeIdentifyQueueItem(entityID: entityID)
    }
    public func searchIdentifyItem(
        entityID: UUID,
        provider: String?,
        query: AdministrativeIdentifyQuery?
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await client.searchAdministrativeIdentifyQueueItem(entityID: entityID, provider: provider, query: query)
    }
    public func resolveIdentifyCandidate(
        entityID: UUID,
        provider: String,
        candidate: AdministrativeEntitySearchCandidate
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await client.resolveAdministrativeIdentifyQueueCandidate(
            entityID: entityID,
            provider: provider,
            candidate: candidate
        )
    }
    public func applyIdentifyItem(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal?,
        selectedFields: [String],
        selectedImages: [String: String?]?,
        progressID: UUID?
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await client.applyAdministrativeIdentifyQueueItem(
            entityID: entityID,
            proposal: proposal,
            selectedFields: selectedFields,
            selectedImages: selectedImages,
            progressID: progressID
        )
    }
    public func saveIdentifyProposal(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal
    ) async throws -> AdministrativeIdentifyQueueItem {
        try await client.saveAdministrativeIdentifyQueueProposal(entityID: entityID, proposal: proposal)
    }
    public func identifyApplyProgress(
        entityID: UUID,
        progressID: UUID
    ) async throws -> AdministrativeIdentifyApplyProgress {
        try await client.administrativeIdentifyApplyProgress(entityID: entityID, progressID: progressID)
    }
    public func startBulkIdentify(
        provider: String?,
        entityIDs: [UUID],
        query: AdministrativeIdentifyQuery?
    ) async throws -> AdministrativeIdentifyBulkAcceptedResponse {
        try await client.startAdministrativeBulkIdentify(provider: provider, entityIDs: entityIDs, query: query)
    }
    public func identifyEntity(
        entityID: UUID,
        provider: String,
        query: AdministrativeIdentifyQuery?,
        parentExternalIDs: [String: String]?
    ) async throws -> AdministrativeEntityMetadataProposal {
        try await client.identifyAdministrativeEntity(
            entityID: entityID,
            provider: provider,
            query: query,
            parentExternalIDs: parentExternalIDs
        )
    }
    public func applyIdentifyProposal(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal,
        selectedFields: [String],
        selectedImages: [String: String?]?
    ) async throws {
        try await client.applyAdministrativeIdentifyProposal(
            entityID: entityID,
            proposal: proposal,
            selectedFields: selectedFields,
            selectedImages: selectedImages
        )
    }
    public func removeIdentifyItem(entityID: UUID) async throws {
        _ = try await client.removeAdministrativeIdentifyQueueItem(entityID: entityID)
    }
    public func plugins() async throws -> [AdministrativePlugin] { try await client.listAdministrativePlugins() }
    public func updatePlugin(id: String) async throws -> AdministrativePlugin {
        try await client.updateAdministrativePlugin(id: id)
    }
    public func searchRequests(kind: String, pluginID: String, fields: [String: String], limit: Int? = nil) async throws
        -> AdministrativeRequestSearchResponse
    {
        try await client.searchAdministrativeRequests(kind: kind, pluginID: pluginID, fields: fields, limit: limit)
    }
    public func reviewRequest(
        kind: String,
        pluginID: String,
        externalIdentity: AdministrativeExternalIdentity
    ) async throws -> AdministrativeRequestReviewResponse {
        try await client.reviewAdministrativeRequest(
            kind: kind,
            pluginID: pluginID,
            externalIdentity: externalIdentity
        )
    }
    public func reviewEntityRequest(entityID: UUID, kind: String) async throws -> AdministrativeRequestReviewResponse {
        try await client.reviewAdministrativeEntityRequest(entityID: entityID, kind: kind)
    }
    public func commitReviewedRequest(
        _ request: AdministrativeReviewedRequestCommitRequest
    ) async throws -> AdministrativeRequestCommitResponse {
        try await client.commitAdministrativeReviewedRequest(request)
    }
    public func libraryRoots() async throws -> [AdministrativeLibraryRoot] {
        try await client.listAdministrativeLibraryRoots()
    }
    public func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile] {
        try await client.listAdministrativeAcquisitionProfiles()
    }
    public func jobs() async throws -> AdministrativeJobListResponse { try await client.listAdministrativeJobs() }
    public func createJob(type: String) async throws -> AdministrativeJobRun {
        try await client.createAdministrativeJob(type: type).job
    }
    public func cancelJob(id: UUID) async throws -> Int {
        try await client.cancelAdministrativeJob(id: id).cancelled ?? 0
    }
    public func cancelJobs(type: String?) async throws -> Int {
        try await client.cancelAdministrativeJobs(type: type).cancelled ?? 0
    }
    public func clearFailures(type: String?) async throws -> Int {
        try await client.clearAdministrativeJobFailures(type: type).cleared ?? 0
    }
    public func rebuildPreviews() async throws -> AdministrativeBulkJobResponse {
        try await client.rebuildAdministrativePreviews()
    }
    public func settings() async throws -> AdministrativeSettingsCatalog {
        try await client.loadAdministrativeSettings()
    }
    public func updateSetting(key: String, value: AdministrativeJSONValue) async throws -> AdministrativeSetting {
        try await client.updateAdministrativeSetting(key: key, value: value)
    }
    public func transcodeCacheStatus() async throws -> AdministrativeTranscodeCacheStatus {
        try await client.administrativeTranscodeCacheStatus()
    }
    public func clearTranscodeCache() async throws -> AdministrativeTranscodeCacheStatus {
        try await client.clearAdministrativeTranscodeCache()
    }
    public func createDatabaseBackup() async throws -> AdministrativeDatabaseBackup {
        try await client.createAdministrativeDatabaseBackup()
    }
}
