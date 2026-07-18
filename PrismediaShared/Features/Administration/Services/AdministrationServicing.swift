import Foundation

public protocol AdministrationServicing: Sendable {
    func fileRoots() async throws -> [AdministrativeFileRoot]
    func fileChildren(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse
    func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse
    func identifyQueue() async throws -> [AdministrativeIdentifyQueueItem]
    func identifyProviders(kind: String?) async throws -> [AdministrativePlugin]
    func identifyQueueItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem
    func addIdentifyItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem
    func searchIdentifyItem(entityID: UUID, provider: String?, query: AdministrativeIdentifyQuery?) async throws
        -> AdministrativeIdentifyQueueItem
    func resolveIdentifyCandidate(
        entityID: UUID,
        provider: String,
        candidate: AdministrativeEntitySearchCandidate
    ) async throws -> AdministrativeIdentifyQueueItem
    func applyIdentifyItem(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal?,
        selectedFields: [String],
        selectedImages: [String: String?]?,
        progressID: UUID?
    ) async throws -> AdministrativeIdentifyQueueItem
    func saveIdentifyProposal(entityID: UUID, proposal: AdministrativeEntityMetadataProposal) async throws
        -> AdministrativeIdentifyQueueItem
    func identifyApplyProgress(entityID: UUID, progressID: UUID) async throws -> AdministrativeIdentifyApplyProgress
    func startBulkIdentify(provider: String?, entityIDs: [UUID], query: AdministrativeIdentifyQuery?) async throws
        -> AdministrativeIdentifyBulkAcceptedResponse
    func identifyEntity(
        entityID: UUID,
        provider: String,
        query: AdministrativeIdentifyQuery?,
        parentExternalIDs: [String: String]?
    ) async throws -> AdministrativeEntityMetadataProposal
    func applyIdentifyProposal(
        entityID: UUID,
        proposal: AdministrativeEntityMetadataProposal,
        selectedFields: [String],
        selectedImages: [String: String?]?
    ) async throws
    func removeIdentifyItem(entityID: UUID) async throws
    func plugins() async throws -> [AdministrativePlugin]
    func updatePlugin(id: String) async throws -> AdministrativePlugin
    func searchRequests(kind: String, pluginID: String, fields: [String: String]) async throws
        -> AdministrativeRequestSearchResponse
    func reviewRequest(kind: String, pluginID: String, externalIdentity: AdministrativeExternalIdentity) async throws
        -> AdministrativeRequestReviewResponse
    func reviewEntityRequest(entityID: UUID, kind: String) async throws -> AdministrativeRequestReviewResponse
    func commitReviewedRequest(_ request: AdministrativeReviewedRequestCommitRequest) async throws
        -> AdministrativeRequestCommitResponse
    func libraryRoots() async throws -> [AdministrativeLibraryRoot]
    func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile]
    func jobs() async throws -> AdministrativeJobListResponse
    func createJob(type: String) async throws -> AdministrativeJobRun
    func cancelJob(id: UUID) async throws -> Int
    func cancelJobs(type: String?) async throws -> Int
    func clearFailures(type: String?) async throws -> Int
    func rebuildPreviews() async throws -> AdministrativeBulkJobResponse
    func settings() async throws -> AdministrativeSettingsCatalog
    func updateSetting(key: String, value: AdministrativeJSONValue) async throws -> AdministrativeSetting
    func transcodeCacheStatus() async throws -> AdministrativeTranscodeCacheStatus
    func clearTranscodeCache() async throws -> AdministrativeTranscodeCacheStatus
    func createDatabaseBackup() async throws -> AdministrativeDatabaseBackup
}
