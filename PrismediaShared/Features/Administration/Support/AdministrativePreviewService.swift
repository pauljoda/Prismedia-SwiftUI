import Foundation

#if DEBUG
    struct AdministrativePreviewService: AdministrationServicing {
        static let setting = AdministrativeSetting(
            key: "scan.intervalMinutes",
            groupKey: "library",
            label: "Scan interval",
            description: "Minutes between automatic library scans.",
            type: "number",
            value: .number(30),
            defaultValue: .number(60),
            isDefault: false,
            order: 0,
            constraints: AdministrativeSettingConstraints(
                minimum: 5,
                maximum: 1_440,
                step: 5,
                minItems: nil,
                maxItems: nil
            ),
            options: [],
            inputKind: nil,
            applyHint: "Applies to the next scheduler window."
        )

        static let fileRootID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!

        func fileRoots() async throws -> [AdministrativeFileRoot] {
            [
                AdministrativeFileRoot(
                    id: Self.fileRootID,
                    label: "Movies",
                    path: "/media/movies",
                    enabled: true
                )
            ]
        }
        func fileChildren(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse {
            AdministrativeFileChildrenResponse(rootID: rootID, path: path, entries: [])
        }
        func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse {
            AdministrativeFileOperationResponse(scansQueued: 1)
        }
        func identifyQueue() async throws -> [AdministrativeIdentifyQueueItem] { [] }
        func identifyProviders(kind: String?) async throws -> [AdministrativePlugin] { [] }
        func identifyQueueItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
            throw CancellationError()
        }
        func addIdentifyItem(entityID: UUID) async throws -> AdministrativeIdentifyQueueItem {
            throw CancellationError()
        }
        func searchIdentifyItem(
            entityID: UUID,
            provider: String?,
            query: AdministrativeIdentifyQuery?
        ) async throws -> AdministrativeIdentifyQueueItem { throw CancellationError() }
        func resolveIdentifyCandidate(
            entityID: UUID,
            provider: String,
            candidate: AdministrativeEntitySearchCandidate
        ) async throws -> AdministrativeIdentifyQueueItem { throw CancellationError() }
        func applyIdentifyItem(
            entityID: UUID,
            proposal: AdministrativeEntityMetadataProposal?,
            selectedFields: [String],
            selectedImages: [String: String?]?,
            progressID: UUID?
        ) async throws -> AdministrativeIdentifyQueueItem { throw CancellationError() }
        func saveIdentifyProposal(
            entityID: UUID,
            proposal: AdministrativeEntityMetadataProposal
        ) async throws -> AdministrativeIdentifyQueueItem { throw CancellationError() }
        func identifyApplyProgress(
            entityID: UUID,
            progressID: UUID
        ) async throws -> AdministrativeIdentifyApplyProgress { throw CancellationError() }
        func startBulkIdentify(
            provider: String?,
            entityIDs: [UUID],
            query: AdministrativeIdentifyQuery?
        ) async throws -> AdministrativeIdentifyBulkAcceptedResponse { throw CancellationError() }
        func identifyEntity(
            entityID: UUID,
            provider: String,
            query: AdministrativeIdentifyQuery?,
            parentExternalIDs: [String: String]?
        ) async throws -> AdministrativeEntityMetadataProposal { throw CancellationError() }
        func applyIdentifyProposal(
            entityID: UUID,
            proposal: AdministrativeEntityMetadataProposal,
            selectedFields: [String],
            selectedImages: [String: String?]?
        ) async throws {}
        func removeIdentifyItem(entityID: UUID) async throws {}
        func plugins() async throws -> [AdministrativePlugin] { [] }
        func updatePlugin(id: String) async throws -> AdministrativePlugin { throw CancellationError() }
        func searchRequests(kind: String, pluginID: String, fields: [String: String]) async throws
            -> AdministrativeRequestSearchResponse
        {
            AdministrativeRequestSearchResponse(results: [], providerErrors: [])
        }
        func reviewRequest(
            kind: String,
            pluginID: String,
            externalIdentity: AdministrativeExternalIdentity
        ) async throws -> AdministrativeRequestReviewResponse { throw CancellationError() }
        func reviewEntityRequest(entityID: UUID, kind: String) async throws -> AdministrativeRequestReviewResponse {
            throw CancellationError()
        }
        func commitReviewedRequest(
            _ request: AdministrativeReviewedRequestCommitRequest
        ) async throws -> AdministrativeRequestCommitResponse { throw CancellationError() }
        func libraryRoots() async throws -> [AdministrativeLibraryRoot] { [] }
        func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile] { [] }
        func jobs() async throws -> AdministrativeJobListResponse {
            AdministrativeJobListResponse(items: [], counts: [])
        }
        func cancelJob(id: UUID) async throws -> Int { 0 }
        func clearFailures(type: String) async throws -> Int { 0 }
        func rebuildPreviews() async throws -> AdministrativeBulkJobResponse {
            AdministrativeBulkJobResponse(enqueued: 0, skipped: 0)
        }
        func settings() async throws -> AdministrativeSettingsCatalog {
            AdministrativeSettingsCatalog(groups: [
                AdministrativeSettingsGroup(
                    key: "library",
                    label: "Library",
                    description: "Scanning and organization settings.",
                    order: 0,
                    settings: [Self.setting]
                )
            ])
        }
        func updateSetting(key: String, value: AdministrativeJSONValue) async throws -> AdministrativeSetting {
            Self.setting
        }
        func transcodeCacheStatus() async throws -> AdministrativeTranscodeCacheStatus {
            AdministrativeTranscodeCacheStatus(usedBytes: 512_000_000, maxBytes: 4_000_000_000)
        }
        func clearTranscodeCache() async throws -> AdministrativeTranscodeCacheStatus {
            AdministrativeTranscodeCacheStatus(usedBytes: 0, maxBytes: 4_000_000_000)
        }
        func createDatabaseBackup() async throws -> AdministrativeDatabaseBackup { throw CancellationError() }
    }
#endif
