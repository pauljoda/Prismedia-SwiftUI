import Foundation

/// App-facing adapter factory for the feature-owned Entity Detail ports.
@MainActor
enum PrismediaEntityDetailComposition {
    static func dependencies(
        client: PrismediaAPIClient,
        userID: UUID,
        isAdministrator: Bool,
        onEntityMutated: @escaping @MainActor @Sendable () -> Void
    ) -> EntityDetailDependencies {
        let adapter = PrismediaEntityDetailLoader(client: client)
        #if DEBUG
            let readerLocatorStore: EPUBLocatorStore =
                CommandLine.arguments.contains("-prismedia-ui-testing") ? .disabled : .standard
            let readerBookmarkStore: any EPUBBookmarkStoring =
                CommandLine.arguments.contains("-prismedia-ui-testing")
                ? EPUBBookmarkStore.disabled
                : EPUBBookmarkStore.standard(
                    scope: EPUBBookmarkScope(serverURL: client.serverURL, userID: userID)
                )
        #else
            let readerLocatorStore: EPUBLocatorStore = .standard
            let readerBookmarkStore: any EPUBBookmarkStoring = EPUBBookmarkStore.standard(
                scope: EPUBBookmarkScope(serverURL: client.serverURL, userID: userID)
            )
        #endif
        return EntityDetailDependencies(
            detailLoader: adapter,
            mutator: adapter,
            collectionItemsLoader: adapter,
            readerService: adapter,
            videoPlaybackService: adapter,
            onEntityMutated: onEntityMutated,
            audioPlaybackService: client,
            acquisitionService: isAdministrator
                ? PrismediaEntityAcquisitionService(client: client)
                : nil,
            imageSourceLoader: adapter,
            imageVideoAspectRatioLoader: PrismediaEntityImageVideoAspectRatioLoader(
                client: client
            ),
            mediaSequenceLoader: EntityGridMediaSequenceLoader(
                loader: PrismediaEntityGridLoader(client: client)
            ),
            transcriptSourceLoader: adapter,
            trickplayFrameLoader: PrismediaTrickplayFrameLoader(client: client),
            entityGridLoader: PrismediaEntityGridLoader(client: client),
            metadataMutator: adapter,
            readerBookmarkStore: readerBookmarkStore,
            readerLocatorStore: readerLocatorStore
        )
    }
}
