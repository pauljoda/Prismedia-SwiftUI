import Foundation

public protocol AdministrationServicing: AcquisitionBlocklistServicing, AdministrativeJobServicing, Sendable {
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
    func searchRequests(kind: String, pluginID: String, fields: [String: String], limit: Int?) async throws
        -> AdministrativeRequestSearchResponse
    func reviewRequest(kind: String, pluginID: String, externalIdentity: AdministrativeExternalIdentity) async throws
        -> AdministrativeRequestReviewResponse
    func requestReview(reviewID: UUID) async throws -> AdministrativeRequestReviewResponse
    func reviewEntityRequest(entityID: UUID, kind: String) async throws -> AdministrativeRequestReviewResponse
    func commitReviewedRequest(_ request: AdministrativeReviewedRequestCommitRequest) async throws
        -> AdministrativeRequestCommitResponse
    func libraryRoots() async throws -> [AdministrativeLibraryRoot]
    func accessibleLibraryRoots() async throws -> [RequestLibraryRoot]
    func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile]
    func updateAcquisitionProfileTiming(
        _ profile: AdministrativeAcquisitionProfile,
        searchAfterDateType: EntityDateType?,
        searchDelayDays: Int
    ) async throws -> AdministrativeAcquisitionProfile
    func rebuildPreviews() async throws -> AdministrativeBulkJobResponse
    func settings() async throws -> AdministrativeSettingsCatalog
    func settingValues(keys: [String]) async throws -> AdministrativeSettingsValuesResponse
    func updateSetting(key: String, value: AdministrativeJSONValue) async throws -> AdministrativeSetting
    func transcodeCacheStatus() async throws -> AdministrativeTranscodeCacheStatus
    func clearTranscodeCache() async throws -> AdministrativeTranscodeCacheStatus
    func createDatabaseBackup() async throws -> AdministrativeDatabaseBackup
}

extension AdministrationServicing {
    public func updateAcquisitionProfileTiming(
        _ profile: AdministrativeAcquisitionProfile,
        searchAfterDateType: EntityDateType?,
        searchDelayDays: Int
    ) async throws -> AdministrativeAcquisitionProfile {
        throw CancellationError()
    }
}
