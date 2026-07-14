import Foundation

#if DEBUG && (os(iOS) || os(macOS))
    enum RequestActivityPreviewFixtures {
        static let referenceDate = Date(timeIntervalSince1970: 1_783_883_400)
        static let acquisitionID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        static let download: RequestActivityDownload = decode(
            """
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
            }
            """
        )

        static let wantedItem: RequestActivityWantedItem = decode(
            """
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
            """
        )

        static let historyEntry: RequestActivityHistoryEntry = decode(
            """
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
            """
        )

        static let candidate: RequestActivityReleaseCandidate = decode(
            """
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
            }
            """
        )

        private static func decode<Value: Decodable>(_ json: String) -> Value {
            try! PrismediaJSON.decoder().decode(Value.self, from: Data(json.utf8))
        }
    }
#endif
