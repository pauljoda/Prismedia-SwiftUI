import Foundation

#if DEBUG && (os(iOS) || os(macOS))
    enum MetadataReviewPreviewFixtures {
        static let proposal = AdministrativeEntityMetadataProposal(
            proposalID: "movie:329865",
            provider: "tmdb",
            targetKind: "movie",
            confidence: 1,
            matchReason: "external-id",
            patch: AdministrativeEntityMetadataPatch(
                title: "Arrival",
                description: "A linguist works to understand visitors who arrived from another world.",
                externalIDs: ["tmdb": "329865"],
                urls: [],
                tags: ["Science Fiction", "Drama"],
                studio: "FilmNation Entertainment",
                credits: [
                    AdministrativeCreditPatch(
                        name: "Amy Adams", role: "actor", character: "Louise Banks", sortOrder: 1)
                ],
                dates: ["release": "2016-11-10"],
                stats: ["runtimeMinutes": 116],
                positions: [:],
                classification: "PG-13",
                rating: nil,
                flags: nil
            ),
            images: [
                AdministrativeImageCandidate(
                    kind: "poster",
                    url: "",
                    source: "tmdb",
                    rank: 1,
                    language: "en",
                    width: 342,
                    height: 513
                )
            ],
            children: [],
            candidates: [],
            targetEntityID: nil,
            relationships: [
                AdministrativeEntityMetadataProposal(
                    proposalID: "person:amy-adams",
                    provider: "tmdb",
                    targetKind: "person",
                    confidence: 1,
                    matchReason: "relationship",
                    patch: AdministrativeEntityMetadataPatch(
                        title: "Amy Adams",
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
                    targetEntityID: nil,
                    relationships: []
                )
            ]
        )
    }
#endif
