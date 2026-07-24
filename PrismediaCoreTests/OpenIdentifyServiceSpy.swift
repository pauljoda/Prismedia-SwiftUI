import Foundation

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    actor OpenIdentifyServiceSpy: AdministrationServicing {
        private let item: AdministrativeIdentifyQueueItem
        private var getCalls = 0
        private var addCalls = 0
        private var searchCalls = 0
        private var queue: [AdministrativeIdentifyQueueItem]
        private var getItems: [AdministrativeIdentifyQueueItem]?
        private let providers: [AdministrativePlugin]
        private let settingValues: [String: AdministrativeJSONValue]
        private var events: [String] = []

        init(
            item: AdministrativeIdentifyQueueItem,
            queue: [AdministrativeIdentifyQueueItem] = [],
            getItems: [AdministrativeIdentifyQueueItem]? = nil,
            providers: [AdministrativePlugin] = [],
            settingValues: [String: AdministrativeJSONValue] = [:]
        ) {
            self.item = item
            self.queue = queue
            self.getItems = getItems
            self.providers = providers
            self.settingValues = settingValues
        }

        func callCounts() -> (get: Int, add: Int, search: Int) { (getCalls, addCalls, searchCalls) }
        func callOrder() -> [String] { events }
        func identifyQueueItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
            getCalls += 1
            events.append("get")
            if let next = getItems?.first {
                getItems?.removeFirst()
                return next
            }
            throw PrismediaAPIError.httpStatus(404, nil)
        }
        func addIdentifyItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
            addCalls += 1
            events.append("add")
            return item
        }
        func searchIdentifyItem(entityID: UUID, provider: String?, query: AdministrativeIdentifyQuery?) async throws
            -> AdministrativeIdentifyQueueItem
        {
            searchCalls += 1
            events.append("search")
            return item
        }

        func fileRoots() async throws -> [AdministrativeFileRoot] { throw CancellationError() }
        func fileChildren(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse {
            throw CancellationError()
        }
        func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse {
            throw CancellationError()
        }
        func identifyQueue() async throws -> [AdministrativeIdentifyQueueItem] { queue }
        func identifyProviders(kind: String?) async throws -> [AdministrativePlugin] { providers }
        func resolveIdentifyCandidate(entityID: UUID, provider: String, candidate: AdministrativeEntitySearchCandidate)
            async throws -> AdministrativeIdentifyQueueItem
        { throw CancellationError() }
        func applyIdentifyItem(
            entityID: UUID, proposal: AdministrativeEntityMetadataProposal?, selectedFields: [String],
            selectedImages: [String: String?]?, progressID: UUID?
        ) async throws -> AdministrativeIdentifyQueueItem { throw CancellationError() }
        func saveIdentifyProposal(entityID: UUID, proposal: AdministrativeEntityMetadataProposal) async throws
            -> AdministrativeIdentifyQueueItem
        { throw CancellationError() }
        func identifyApplyProgress(entityID: UUID, progressID: UUID) async throws -> AdministrativeIdentifyApplyProgress
        { throw CancellationError() }
        func startBulkIdentify(provider: String?, entityIDs: [UUID], query: AdministrativeIdentifyQuery?) async throws
            -> AdministrativeIdentifyBulkAcceptedResponse
        { throw CancellationError() }
        func identifyEntity(
            entityID: UUID, provider: String, query: AdministrativeIdentifyQuery?, parentExternalIDs: [String: String]?
        ) async throws -> AdministrativeEntityMetadataProposal { throw CancellationError() }
        func applyIdentifyProposal(
            entityID: UUID, proposal: AdministrativeEntityMetadataProposal, selectedFields: [String],
            selectedImages: [String: String?]?
        ) async throws { throw CancellationError() }
        func removeIdentifyItem(entityID: UUID) async throws { throw CancellationError() }
        func plugins() async throws -> [AdministrativePlugin] { throw CancellationError() }
        func updatePlugin(id: String) async throws -> AdministrativePlugin { throw CancellationError() }
        func searchRequests(kind: String, pluginID: String, fields: [String: String], limit: Int?) async throws
            -> AdministrativeRequestSearchResponse
        { throw CancellationError() }
        func reviewRequest(kind: String, pluginID: String, externalIdentity: AdministrativeExternalIdentity)
            async throws -> AdministrativeRequestReviewResponse
        { throw CancellationError() }
        func reviewEntityRequest(entityID: UUID, kind: String) async throws -> AdministrativeRequestReviewResponse {
            throw CancellationError()
        }
        func commitReviewedRequest(_ request: AdministrativeReviewedRequestCommitRequest) async throws
            -> AdministrativeRequestCommitResponse
        { throw CancellationError() }
        func libraryRoots() async throws -> [AdministrativeLibraryRoot] { throw CancellationError() }
        func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile] { throw CancellationError() }
        func acquisitionBlocklist(entityID: UUID?) async throws -> [RequestActivityBlocklistEntry] { [] }
        func clearAcquisitionBlocklist(entityID: UUID?, createdAfter: Date?) async throws -> Int { 0 }
        func jobs() async throws -> AdministrativeJobListResponse { throw CancellationError() }
        func createJob(type: String) async throws -> AdministrativeJobRun { throw CancellationError() }
        func cancelJob(id: UUID) async throws -> Int { throw CancellationError() }
        func cancelJobs(type: String?) async throws -> Int { throw CancellationError() }
        func clearFailures(type: String?) async throws -> Int { throw CancellationError() }
        func rebuildPreviews() async throws -> AdministrativeBulkJobResponse { throw CancellationError() }
        func settings() async throws -> AdministrativeSettingsCatalog { throw CancellationError() }
        func settingValues(keys: [String]) async throws -> AdministrativeSettingsValuesResponse {
            AdministrativeSettingsValuesResponse(
                values: settingValues.filter { keys.contains($0.key) }
            )
        }
        func updateSetting(key: String, value: AdministrativeJSONValue) async throws -> AdministrativeSetting {
            throw CancellationError()
        }
        func transcodeCacheStatus() async throws -> AdministrativeTranscodeCacheStatus { throw CancellationError() }
        func clearTranscodeCache() async throws -> AdministrativeTranscodeCacheStatus { throw CancellationError() }
        func createDatabaseBackup() async throws -> AdministrativeDatabaseBackup { throw CancellationError() }
    }
#endif
