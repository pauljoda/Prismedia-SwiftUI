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
        static let cascadeProposal = AdministrativeEntityMetadataProposal(
            proposalID: "openlibrary-narnia",
            provider: "Open Library",
            targetKind: "video-series",
            confidence: 0.94,
            matchReason: "Series title match",
            patch: AdministrativeEntityMetadataPatch(
                title: "The Chronicles of Narnia",
                description: "A fantasy series set in the world of Narnia.",
                externalIDs: ["openlibrary": "OL-NARNIA"],
                urls: [],
                tags: ["Fantasy", "Family", "Adventure"],
                studio: nil,
                credits: [],
                dates: ["release": "2005"],
                stats: [:],
                positions: [:],
                classification: nil,
                rating: nil,
                flags: nil
            ),
            images: [
                AdministrativeImageCandidate(
                    kind: "poster",
                    url: "",
                    source: "openlibrary",
                    rank: 1,
                    language: "en",
                    width: 600,
                    height: 900
                ),
                AdministrativeImageCandidate(
                    kind: "header",
                    url: "",
                    source: "openlibrary",
                    rank: 1,
                    language: "en",
                    width: 1200,
                    height: 500
                ),
            ],
            children: [matchedChildProposal],
            candidates: [],
            targetEntityID: nil,
            relationships: [
                relationshipProposal(
                    id: "tag-fantasy",
                    title: "Fantasy",
                    targetEntityID: UUID(uuidString: "a3000000-0000-0000-0000-000000000001")
                ),
                relationshipProposal(
                    id: "tag-adventure",
                    title: "Adventure",
                    targetEntityID: nil
                ),
            ]
        )
        static let cascadeItem = queueItem(
            id: "b1000000-0000-0000-0000-000000000003",
            entityID: "b2000000-0000-0000-0000-000000000003",
            entityKind: "video-series",
            title: "The Chronicles of Narnia",
            state: "proposal",
            provider: "Open Library",
            proposal: cascadeProposal,
            error: nil,
            cascadeRunning: true
        )
        static let cascadeDetail = EntityDetail(
            id: cascadeItem.entityID,
            kind: .videoSeries,
            title: "The Chronicles of Narnia",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: true,
            capabilities: [],
            childrenByKind: [
                EntityGroup(
                    kind: .video,
                    label: "Episodes",
                    entities: cascadeChildren,
                    code: nil
                )
            ],
            relationships: [
                EntityGroup(
                    kind: .tag,
                    label: "Tags",
                    entities: [
                        EntityThumbnail(
                            id: UUID(uuidString: "a3000000-0000-0000-0000-000000000001")!,
                            kind: .tag,
                            title: "Fantasy"
                        )
                    ],
                    code: nil
                )
            ]
        )
        static let cascadeReviewItems = IdentifyChildReviewPolicy.items(
            children: cascadeChildren,
            proposal: cascadeProposal,
            cascadeRunning: true
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
            entityKind: String = "movie",
            title: String,
            state: String,
            provider: String?,
            proposal: AdministrativeEntityMetadataProposal?,
            error: String?,
            cascadeRunning: Bool = false
        ) -> AdministrativeIdentifyQueueItem {
            var object: [String: Any] = [
                "id": id,
                "entityId": entityID,
                "entityKind": entityKind,
                "title": title,
                "isNsfw": false,
                "state": state,
                "action": "identify",
                "candidates": [],
                "cascadeRunning": cascadeRunning,
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

        private static let cascadeChildren = [
            EntityThumbnail(
                id: UUID(uuidString: "a1000000-0000-0000-0000-000000000011")!,
                kind: .video,
                title: "The Lion, the Witch and the Wardrobe",
                parentEntityID: UUID(uuidString: "b2000000-0000-0000-0000-000000000003"),
                parentKind: .videoSeries,
                hasSourceMedia: true
            ),
            EntityThumbnail(
                id: UUID(uuidString: "a1000000-0000-0000-0000-000000000012")!,
                kind: .video,
                title: "Prince Caspian",
                parentEntityID: UUID(uuidString: "b2000000-0000-0000-0000-000000000003"),
                parentKind: .videoSeries,
                hasSourceMedia: true
            ),
            EntityThumbnail(
                id: UUID(uuidString: "a1000000-0000-0000-0000-000000000013")!,
                kind: .video,
                title: "The Voyage of the Dawn Treader",
                parentEntityID: UUID(uuidString: "b2000000-0000-0000-0000-000000000003"),
                parentKind: .videoSeries,
                hasSourceMedia: true
            ),
        ]

        private static let matchedChildProposal = AdministrativeEntityMetadataProposal(
            proposalID: "narnia-child-1",
            provider: "Open Library",
            targetKind: "video",
            confidence: 0.92,
            matchReason: "Title match",
            patch: AdministrativeEntityMetadataPatch(
                title: "The Lion, the Witch and the Wardrobe",
                description: "Four siblings discover Narnia.",
                externalIDs: [:],
                urls: [],
                tags: [],
                studio: nil,
                credits: [],
                dates: [:],
                stats: [:],
                positions: [:],
                classification: nil,
                rating: nil,
                flags: nil
            ),
            images: [],
            children: [],
            candidates: [],
            targetEntityID: UUID(uuidString: "a1000000-0000-0000-0000-000000000011"),
            relationships: []
        )

        private static func relationshipProposal(
            id: String,
            title: String,
            targetEntityID: UUID?
        ) -> AdministrativeEntityMetadataProposal {
            AdministrativeEntityMetadataProposal(
                proposalID: id,
                provider: "Open Library",
                targetKind: "tag",
                confidence: 1,
                matchReason: "Related metadata",
                patch: AdministrativeEntityMetadataPatch(
                    title: title,
                    description: nil,
                    externalIDs: [:],
                    urls: [],
                    tags: [],
                    studio: nil,
                    credits: [],
                    dates: [:],
                    stats: [:],
                    positions: [:],
                    classification: nil,
                    rating: nil,
                    flags: nil
                ),
                images: [],
                children: [],
                candidates: [],
                targetEntityID: targetEntityID,
                relationships: []
            )
        }
    }
#endif
