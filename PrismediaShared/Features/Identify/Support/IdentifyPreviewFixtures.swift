import Foundation

#if DEBUG && (os(iOS) || os(macOS))
    enum IdentifyPreviewFixtures {
        static let proposal = AdministrativeEntityMetadataProposal(
            proposalID: "tmdb-arrival",
            provider: "TMDB",
            targetKind: "movie",
            confidence: 0.96,
            matchReason: "Title and year match",
            patch: AdministrativeEntityMetadataPatch(
                title: "Arrival (2016)",
                description: "A linguist works with the military to communicate with alien lifeforms.",
                externalIDs: ["tmdb": "329865"],
                urls: [],
                tags: ["Science Fiction", "Drama"],
                studio: "Paramount Pictures",
                credits: [],
                dates: ["release": "2016-11-11"],
                stats: [:],
                positions: [:],
                classification: "PG-13",
                rating: 8,
                flags: nil),
            images: [],
            children: [],
            candidates: [],
            targetEntityID: nil,
            relationships: [])

        static let reviewItem = queueItem(
            id: "b1000000-0000-0000-0000-000000000001",
            entityID: "b2000000-0000-0000-0000-000000000001",
            title: "Arrival",
            state: "proposal",
            provider: "TMDB",
            proposal: proposal,
            error: nil
        )
        static let errorItem = queueItem(
            id: "b1000000-0000-0000-0000-000000000002",
            entityID: "b2000000-0000-0000-0000-000000000002",
            title: "Unknown Feature",
            state: "error",
            provider: "TMDB",
            proposal: nil,
            error: "No matching external identity was found."
        )

        static let provider = AdministrativePlugin(
            id: "tmdb", name: "TMDB", version: "1.0", installed: true, enabled: true, isNsfw: false,
            supports: [
                AdministrativePluginSupport(
                    entityKind: "movie", actions: ["search", "lookup-id"],
                    search: AdministrativePluginSearchDefinition(fields: [
                        AdministrativePluginSearchField(
                            key: "title", label: "Title", type: "text", required: true,
                            placeholder: "Movie title", help: nil),
                        AdministrativePluginSearchField(
                            key: "year", label: "Year", type: "year", required: false,
                            placeholder: "2016", help: nil),
                    ]))
            ],
            missingAuthKeys: [], updateAvailable: false, availableVersion: nil)

        private static func queueItem(
            id: String,
            entityID: String,
            title: String,
            state: String,
            provider: String?,
            proposal: AdministrativeEntityMetadataProposal?,
            error: String?
        ) -> AdministrativeIdentifyQueueItem {
            var object: [String: Any] = [
                "id": id,
                "entityId": entityID,
                "entityKind": "movie",
                "title": title,
                "isNsfw": false,
                "state": state,
                "action": "identify",
                "candidates": [],
                "cascadeRunning": false,
                "createdAt": "2026-07-12T12:00:00Z",
                "updatedAt": "2026-07-12T12:00:00Z",
            ]
            object["provider"] = provider
            object["error"] = error
            if let proposal {
                object["proposal"] = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(proposal))
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try! decoder.decode(
                AdministrativeIdentifyQueueItem.self,
                from: JSONSerialization.data(withJSONObject: object))
        }
    }
#endif
