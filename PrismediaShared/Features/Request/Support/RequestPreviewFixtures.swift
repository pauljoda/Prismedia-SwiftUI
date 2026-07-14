import Foundation

#if DEBUG && (os(iOS) || os(macOS))
    enum RequestPreviewFixtures {
        static let rootID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        static let profileID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        static let route = RequestReviewRoute(
            kind: .movie,
            pluginID: "tmdb",
            externalIdentity: AdministrativeExternalIdentity(namespace: "tmdb", value: "329865")
        )

        static let roots = [
            AdministrativeLibraryRoot(
                id: rootID,
                path: "/media/movies",
                label: "Movies",
                enabled: true,
                scanVideos: true
            )
        ]

        static let profiles = [
            AdministrativeAcquisitionProfile(
                id: profileID,
                kind: .movie,
                displayName: "Movie HD",
                isDefault: true,
                targetLibraryRootID: rootID
            )
        ]

        static let warnings: [AdministrativeRequestProviderError] = {
            let data = Data(
                """
                [
                  {
                    "serviceId":"55555555-5555-5555-5555-555555555555",
                    "kind":"movie",
                    "displayName":"The Movie Database",
                    "message":"The provider is temporarily unavailable."
                  }
                ]
                """.utf8
            )
            return try! PrismediaJSON.decoder().decode([AdministrativeRequestProviderError].self, from: data)
        }()
    }
#endif
