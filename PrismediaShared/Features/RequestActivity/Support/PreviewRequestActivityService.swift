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
            guard [.content, .downloading, .releases].contains(scenario) else { return [] }
            return try decode(historyJSON)
        }

        func fetchRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail {
            switch scenario {
            case .downloading: try decode(downloadingDetailJSON)
            case .releases: try decode(releasesDetailJSON)
            default: try decode(detailJSON)
            }
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

        func fetchRequestActivityTransfer(id: UUID) async throws -> RequestActivityTransfer? {
            guard scenario == .downloading else { return nil }
            return try decode(transferJSON)
        }

        func fetchRequestActivityFiles(id: UUID) async throws -> RequestActivityFiles {
            guard scenario == .downloading else {
                return RequestActivityFiles(imported: false, files: [])
            }
            return try decode(filesJSON)
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
            case .content, .empty, .downloading, .releases:
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

        private var downloadingDetailJSON: String {
            """
            {
              "summary":{
                "id":"11111111-1111-1111-1111-111111111111",
                "status":"downloading",
                "statusMessage":"Fetching release",
                "title":"Dune",
                "author":"Frank Herbert",
                "kind":"book",
                "progress":0.64,
                "createdAt":"2026-07-12T17:00:00Z",
                "updatedAt":"2026-07-12T18:00:00Z",
                "entityId":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
              },
              "candidates":[]
            }
            """
        }

        private var releasesDetailJSON: String {
            """
            {
              "summary":{
                "id":"11111111-1111-1111-1111-111111111111",
                "status":"awaiting-selection",
                "title":"Dune",
                "author":"Frank Herbert",
                "kind":"book",
                "createdAt":"2026-07-12T17:00:00Z",
                "updatedAt":"2026-07-12T18:00:00Z",
                "entityId":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
              },
              "candidates":[
                {
                  "id":"66666666-6666-6666-6666-666666666666",
                  "indexerName":"Prowlarr",
                  "title":"Dune.1965.Retail.EPUB",
                  "sizeBytes":4200000,
                  "seeders":38,
                  "peers":4,
                  "protocol":"torrent",
                  "accepted":true,
                  "score":92.5,
                  "rejections":[],
                  "publishedAt":"2026-07-12T17:45:00Z"
                },
                {
                  "id":"77777777-7777-7777-7777-777777777777",
                  "indexerName":"Prowlarr",
                  "title":"Dune.1965.WEB.PDF",
                  "sizeBytes":9800000,
                  "seeders":6,
                  "peers":2,
                  "protocol":"torrent",
                  "accepted":false,
                  "score":41.0,
                  "rejections":["below-cutoff"],
                  "publishedAt":"2026-07-12T16:10:00Z"
                },
                {
                  "id":"88888888-8888-8888-8888-888888888888",
                  "indexerName":"Usenet Hub",
                  "title":"Dune.1965.Unknown.Archive",
                  "sizeBytes":15600000,
                  "protocol":"usenet",
                  "accepted":false,
                  "score":5.0,
                  "rejections":["unsupported-format"],
                  "publishedAt":"2026-07-11T09:00:00Z"
                }
              ]
            }
            """
        }

        private var transferJSON: String {
            """
            {
              "progress":0.64,
              "state":"downloading",
              "totalSizeBytes":2800000000,
              "downloadSpeedBytesPerSecond":8500000,
              "etaSeconds":780,
              "seeds":24,
              "peers":6,
              "savePath":"/downloads/dune",
              "pieceStates":[2,2,2,1,0]
            }
            """
        }

        private var filesJSON: String {
            """
            {
              "imported":false,
              "files":[
                {"name":"Dune.1965.Retail.epub","sizeBytes":4200000,"progress":0.82},
                {"name":"cover.jpg","sizeBytes":310000,"progress":1.0}
              ]
            }
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
