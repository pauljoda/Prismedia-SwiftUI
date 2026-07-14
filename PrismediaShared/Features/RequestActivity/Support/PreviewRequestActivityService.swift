import Foundation

#if DEBUG
    struct PreviewRequestActivityService: RequestActivityServicing {
        let scenario: RequestActivityPreviewScenario

        func listRequestActivityDownloads() async throws -> [RequestActivityDownload] {
            try await prepare()
            guard scenario == .content else { return [] }
            return try decode(downloadsJSON)
        }

        func listRequestActivityWanted(
            _ list: RequestActivityWantedList,
            page: Int,
            pageSize: Int,
            kind: EntityKind?
        ) async throws -> RequestActivityWantedPage {
            try await prepare()
            guard scenario == .content else { return try decode(#"{"items":[],"total":0}"#) }
            return try decode(wantedJSON)
        }

        func listRequestActivityHistory(
            limit: Int?,
            entityID: UUID?
        ) async throws -> [RequestActivityHistoryEntry] {
            try await prepare()
            guard scenario == .content else { return [] }
            return try decode(historyJSON)
        }

        func fetchRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail {
            try decode(detailJSON)
        }

        func queueRequestActivityRelease(
            acquisitionID: UUID,
            candidateID: UUID
        ) async throws -> RequestActivityAcquisitionDetail {
            try decode(detailJSON)
        }

        func blocklistRequestActivityCandidate(
            acquisitionID: UUID,
            candidateID: UUID
        ) async throws -> RequestActivityAcquisitionDetail {
            try decode(detailJSON)
        }

        func researchRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail {
            try decode(detailJSON)
        }

        func retryRequestActivityImport(
            id: UUID,
            allowFormatChange: Bool
        ) async throws -> RequestActivityAcquisitionDetail {
            try decode(detailJSON)
        }

        func cancelRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail {
            try decode(detailJSON)
        }

        func uploadRequestActivityTorrent(
            _ upload: RequestActivityManualTorrentUpload
        ) async throws -> RequestActivityAcquisitionDetail {
            try decode(detailJSON)
        }

        func removeRequestActivityAcquisition(id: UUID) async throws {}

        func fetchRequestActivityTransfer(id: UUID) async throws -> RequestActivityTransfer? { nil }

        func fetchRequestActivityFiles(id: UUID) async throws -> RequestActivityFiles {
            RequestActivityFiles(imported: false, files: [])
        }

        func listRequestActivityBlocklist() async throws -> [RequestActivityBlocklistEntry] { [] }

        func removeRequestActivityBlocklistEntry(id: UUID) async throws {}

        func pauseMonitor(id: UUID) async throws {}

        func resumeMonitor(id: UUID) async throws {}

        func unmonitor(id: UUID) async throws -> EntityMonitorStopResponse {
            try decode(#"{"entityPruned":false}"#)
        }

        private func prepare() async throws {
            switch scenario {
            case .content, .empty:
                return
            case .loading:
                try await Task.sleep(for: .seconds(3_600))
            case .error:
                throw RequestActivityPreviewError.unavailable
            }
        }

        private func decode<Value: Decodable>(_ json: String) throws -> Value {
            try PrismediaJSON.decoder().decode(Value.self, from: Data(json.utf8))
        }

        private var downloadsJSON: String {
            """
            [
              {
                "acquisitionId":"11111111-1111-1111-1111-111111111111",
                "entityId":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                "kind":"book",
                "title":"Dune",
                "author":"Frank Herbert",
                "status":"downloading",
                "progress":0.64,
                "updatedAt":"2026-07-12T18:00:00Z",
                "totalSizeBytes":2800000000,
                "downloadSpeedBytesPerSecond":8500000,
                "etaSeconds":780,
                "clientName":"qBittorrent"
              },
              {
                "acquisitionId":"22222222-2222-2222-2222-222222222222",
                "entityId":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                "kind":"movie",
                "title":"Arrival",
                "year":2016,
                "status":"awaiting-selection",
                "updatedAt":"2026-07-12T17:00:00Z"
              }
            ]
            """
        }

        private var wantedJSON: String {
            """
            {
              "items":[
                {
                  "monitorId":"33333333-3333-3333-3333-333333333333",
                  "acquisitionId":"44444444-4444-4444-4444-444444444444",
                  "entityId":"cccccccc-cccc-cccc-cccc-cccccccccccc",
                  "kind":"book",
                  "title":"The Left Hand of Darkness",
                  "author":"Ursula K. Le Guin",
                  "monitorStatus":"active",
                  "lastSearchedAt":"2026-07-12T16:00:00Z",
                  "nextSearchAt":"2026-07-13T02:00:00Z",
                  "ownedQuality":"WEB PDF",
                  "cutoffQuality":"Retail EPUB",
                  "barrenSearches":2
                }
              ],
              "total":1
            }
            """
        }

        private var historyJSON: String {
            """
            [
              {
                "id":"55555555-5555-5555-5555-555555555555",
                "acquisitionId":"11111111-1111-1111-1111-111111111111",
                "entityId":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                "kind":"book",
                "event":"grabbed",
                "title":"Dune",
                "releaseTitle":"Dune.1965.EPUB",
                "indexerName":"Prowlarr",
                "downloadClientName":"qBittorrent",
                "qualityCode":"EPUB",
                "createdAt":"2026-07-12T17:55:00Z"
              }
            ]
            """
        }

        private var detailJSON: String {
            """
            {
              "summary":{
                "id":"11111111-1111-1111-1111-111111111111",
                "status":"searching",
                "title":"Dune",
                "kind":"book",
                "createdAt":"2026-07-12T17:00:00Z",
                "updatedAt":"2026-07-12T18:00:00Z"
              },
              "candidates":[]
            }
            """
        }
    }
#endif
