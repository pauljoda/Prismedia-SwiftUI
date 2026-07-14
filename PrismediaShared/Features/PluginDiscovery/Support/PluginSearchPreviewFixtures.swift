import Foundation

#if DEBUG && (os(iOS) || os(macOS))
    enum PluginSearchPreviewFixtures {
        static let provider = AdministrativePlugin(
            id: "tmdb",
            name: "The Movie Database",
            version: "2.4.0",
            installed: true,
            enabled: true,
            isNsfw: false,
            supports: [
                AdministrativePluginSupport(
                    entityKind: "movie",
                    actions: ["search", "lookup-id"],
                    identityNamespaces: ["tmdb"],
                    search: AdministrativePluginSearchDefinition(fields: [
                        AdministrativePluginSearchField(
                            key: "query",
                            label: "Title",
                            type: "text",
                            required: true,
                            placeholder: "Arrival",
                            help: "Use the title as it appeared on release."
                        ),
                        AdministrativePluginSearchField(
                            key: "year",
                            label: "Year",
                            type: "year",
                            required: false,
                            placeholder: "2016",
                            help: "Optional four-digit release year."
                        ),
                    ]),
                    identityUrls: nil
                )
            ],
            auth: [],
            missingAuthKeys: [],
            updateAvailable: false,
            availableVersion: nil
        )

        static let secondProvider = AdministrativePlugin(
            id: "omdb",
            name: "OMDb",
            version: "1.1.0",
            installed: true,
            enabled: true,
            isNsfw: false,
            supports: provider.supports,
            auth: [],
            missingAuthKeys: [],
            updateAvailable: false,
            availableVersion: nil
        )

        static let candidates = [
            AdministrativeEntitySearchCandidate(
                externalIDs: ["tmdb": "329865"],
                title: "Arrival",
                year: 2016,
                overview: "A linguist works with the military to communicate with alien lifeforms.",
                posterURL: "https://images.example.test/arrival.jpg",
                candidateID: "329865",
                source: "tmdb",
                confidence: 0.96,
                matchReason: "Title and year match"
            ),
            AdministrativeEntitySearchCandidate(
                externalIDs: ["tmdb": "56530"],
                title: "The Arrival",
                year: 1996,
                overview: "An astronomer discovers evidence of an alien conspiracy.",
                posterURL: nil,
                candidateID: "56530",
                source: "tmdb",
                confidence: 0.72,
                matchReason: "Similar title"
            ),
        ]
    }
#endif
