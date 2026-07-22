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

        static let transfer: RequestActivityTransfer = decode(
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
        )

        static let stalledTransfer: RequestActivityTransfer = decode(
            """
            {
              "progress":0.42,
              "state":"stalledDL",
              "totalSizeBytes":2800000000,
              "downloadSpeedBytesPerSecond":0,
              "etaSeconds":0,
              "seeds":0,
              "peers":0,
              "savePath":"/downloads/dune",
              "pieceStates":[2,2,1,0,0,0]
            }
            """
        )

        static let pausedTransfer: RequestActivityTransfer = decode(
            """
            {
              "progress":0.51,
              "state":"pausedDL",
              "totalSizeBytes":2800000000,
              "downloadSpeedBytesPerSecond":0,
              "etaSeconds":0,
              "seeds":12,
              "peers":3,
              "savePath":"/downloads/dune",
              "pieceStates":[2,2,2,1,0,0]
            }
            """
        )

        static let failedTransfer: RequestActivityTransfer = decode(
            """
            {
              "progress":0.28,
              "state":"error",
              "totalSizeBytes":2800000000,
              "downloadSpeedBytesPerSecond":0,
              "etaSeconds":0,
              "seeds":0,
              "peers":0,
              "savePath":"/downloads/dune",
              "pieceStates":[2,1,0,0,0]
            }
            """
        )

        static let noSwarmTransfer: RequestActivityTransfer = decode(
            """
            {
              "progress":0.92,
              "state":"Extracting",
              "totalSizeBytes":1400000000,
              "downloadSpeedBytesPerSecond":0,
              "etaSeconds":0,
              "seeds":0,
              "peers":0,
              "savePath":"/downloads/complete/dune",
              "pieceStates":[]
            }
            """
        )

        static let completedTransfer: RequestActivityTransfer = decode(
            """
            {
              "progress":1,
              "state":"Completed",
              "totalSizeBytes":1400000000,
              "downloadSpeedBytesPerSecond":0,
              "etaSeconds":0,
              "seeds":0,
              "peers":0,
              "savePath":"/downloads/complete/dune",
              "pieceStates":[]
            }
            """
        )

        static let unknownStateTransfer: RequestActivityTransfer = decode(
            """
            {
              "progress":0.17,
              "state":"WaitingForRemoteSlot",
              "totalSizeBytes":684000000,
              "downloadSpeedBytesPerSecond":0,
              "etaSeconds":0,
              "seeds":0,
              "peers":0,
              "savePath":null,
              "pieceStates":[]
            }
            """
        )

        static let files: RequestActivityFiles = decode(
            """
            {
              "imported":false,
              "files":[
                {"name":"Dune.1965.Retail.epub","sizeBytes":4200000,"progress":0.82},
                {"name":"cover.jpg","sizeBytes":310000,"progress":1.0}
              ]
            }
            """
        )

        static let rejectedCandidate: RequestActivityReleaseCandidate = decode(
            """
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
            }
            """
        )

        static let categoryCandidate: RequestActivityReleaseCandidate = decode(
            """
            {
              "id":"88888888-8888-8888-8888-888888888888",
              "indexerName":"BookSearch",
              "title":"Dune Messiah    Retail EPUB  »  Books / Ebook",
              "sizeBytes":5100000,
              "seeders":62,
              "peers":8,
              "protocol":"torrent",
              "accepted":true,
              "score":97.4,
              "rejections":[],
              "infoUrl":"https://example.com/releases/dune-messiah",
              "publishedAt":"2026-07-12T18:10:00Z"
            }
            """
        )

        static let unavailableCandidate: RequestActivityReleaseCandidate = decode(
            """
            {
              "id":"99999999-9999-9999-9999-999999999999",
              "indexerName":"Archive Index",
              "title":"Dune.1965.Unknown.Archive » Other",
              "sizeBytes":15600000,
              "protocol":"usenet",
              "accepted":false,
              "score":5.0,
              "rejections":["unsupported-format","no-download-link"],
              "publishedAt":"2026-07-11T09:00:00Z"
            }
            """
        )

        static let blockedCandidate: RequestActivityReleaseCandidate = decode(
            """
            {
              "id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
              "indexerName":"BookSearch",
              "title":"Dune.1965.Retail.MOBI » Books / Ebook",
              "sizeBytes":6300000,
              "seeders":14,
              "peers":1,
              "protocol":"torrent",
              "accepted":false,
              "score":78.0,
              "rejections":["blocklisted"],
              "infoUrl":"https://example.com/releases/dune-mobi",
              "publishedAt":"2026-07-12T12:20:00Z"
            }
            """
        )

        static let soulseekCandidate: RequestActivityReleaseCandidate = decode(
            """
            {
              "id":"bbbbbbbb-cccc-dddd-eeee-ffffffffffff",
              "indexerName":"Soulseek",
              "title":"Dune (Unabridged) M4B » Audio / Audiobook",
              "sizeBytes":684000000,
              "seeders":3,
              "peers":0,
              "protocol":"soulseek",
              "accepted":true,
              "score":88.8,
              "rejections":[],
              "infoUrl":"https://example.com/releases/dune-audio",
              "publishedAt":"2026-07-12T13:30:00Z"
            }
            """
        )

        static let unknownProtocolCandidate: RequestActivityReleaseCandidate = decode(
            """
            {
              "id":"cccccccc-dddd-eeee-ffff-000000000000",
              "indexerName":"Future Indexer",
              "title":"Dune.1965.Retail.PDF » Books / Ebook",
              "sizeBytes":7400000,
              "seeders":null,
              "peers":null,
              "protocol":"future-transfer",
              "accepted":false,
              "score":33.2,
              "rejections":["wrong-protocol"],
              "publishedAt":"2026-07-12T10:00:00Z"
            }
            """
        )

        static var releasePickerCandidates: [RequestActivityReleaseCandidate] {
            [
                categoryCandidate,
                candidate,
                soulseekCandidate,
                rejectedCandidate,
                unavailableCandidate,
                blockedCandidate,
                unknownProtocolCandidate,
            ]
        }

        private static func decode<Value: Decodable>(_ json: String) -> Value {
            try! PrismediaJSON.decoder().decode(Value.self, from: Data(json.utf8))
        }
    }
#endif
