import Foundation

@testable import PrismediaCore

actor EntityGridMutationServiceStub: EntityGridMutationServicing {
    private let failingFlagIDs: Set<UUID>
    private let failingWantedIDs: Set<UUID>
    private var flagCalls: [UUID] = []

    init(failingFlagIDs: Set<UUID> = [], failingWantedIDs: Set<UUID> = []) {
        self.failingFlagIDs = failingFlagIDs
        self.failingWantedIDs = failingWantedIDs
    }

    func loadCollectionOptions() async throws -> [EntityThumbnail] { [] }

    func addToCollection(collectionID _: UUID, item _: CollectionEntityReference) async throws -> Bool {
        true
    }

    func markNsfw(_ isNsfw: Bool, item: EntityThumbnail) async throws {
        flagCalls.append(item.id)
        if failingFlagIDs.contains(item.id) {
            throw URLError(.cannotConnectToHost)
        }
        _ = isNsfw
    }

    func removeWanted(entityID: UUID) async throws -> WantedRemovalResponse {
        if failingWantedIDs.contains(entityID) {
            return WantedRemovalResponse(
                removed: 0,
                failures: [WantedRemovalFailure(entityID: entityID, message: "Still downloading")]
            )
        }
        return WantedRemovalResponse(removed: 1, failures: [])
    }

    func removeCollectionItem(collectionID _: UUID, itemID _: UUID) async throws -> Bool {
        true
    }

    func flaggedIDs() -> [UUID] { flagCalls }
}
