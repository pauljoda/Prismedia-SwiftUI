import XCTest

@testable import PrismediaCore

final class CollectionMembersStateTests: XCTestCase {
    func testCancelledInitialLoadReturnsToIdleAndCanBeRetried() throws {
        let collectionID = UUID()
        var state = CollectionMembersState()
        let request = try XCTUnwrap(state.beginLoad(collectionID: collectionID))

        state.finishLoad(.cancelled, request: request)

        XCTAssertEqual(state.phase, .idle)
        XCTAssertNotNil(state.beginLoad(collectionID: collectionID))
    }

    func testNewCollectionRequestRejectsPriorCollectionResponse() throws {
        let oldCollectionID = UUID()
        let newCollectionID = UUID()
        let staleItem = EntityThumbnail(id: UUID(), kind: .movie, title: "Stale")
        let currentItem = EntityThumbnail(id: UUID(), kind: .book, title: "Current")
        var state = CollectionMembersState()
        let oldRequest = try XCTUnwrap(state.beginLoad(collectionID: oldCollectionID))
        let newRequest = try XCTUnwrap(state.beginLoad(collectionID: newCollectionID))

        state.finishLoad(.content([staleItem]), request: oldRequest)
        state.finishLoad(.content([currentItem]), request: newRequest)

        XCTAssertEqual(state.phase, .content([currentItem]))
    }

    func testCancelledRefreshRestoresPreviouslyLoadedMembers() throws {
        let collectionID = UUID()
        let member = EntityThumbnail(id: UUID(), kind: .gallery, title: "Gallery")
        var state = CollectionMembersState()
        let initialRequest = try XCTUnwrap(state.beginLoad(collectionID: collectionID))
        state.finishLoad(.content([member]), request: initialRequest)
        let refreshRequest = try XCTUnwrap(
            state.beginLoad(collectionID: collectionID, force: true)
        )

        state.finishLoad(.cancelled, request: refreshRequest)

        XCTAssertEqual(state.phase, .content([member]))
    }

}

@MainActor
final class CollectionMembersServiceTests: XCTestCase {
    func testLoadPublishesEveryMemberReturnedByTheCollectionEndpoint() async {
        let collectionID = UUID()
        let members = [
            EntityThumbnail(id: UUID(), kind: .video, title: "Video"),
            EntityThumbnail(id: UUID(), kind: .gallery, title: "Gallery"),
            EntityThumbnail(id: UUID(), kind: .book, title: "Book"),
            EntityThumbnail(id: UUID(), kind: .audioTrack, title: "Song"),
        ]
        let loader = CollectionMembersLoaderStub(members: members)
        let service = CollectionMembersService(loader: loader)

        let outcome = await service.load(collectionID: collectionID)
        let requestedIDs = await loader.requestedCollectionIDs()

        XCTAssertEqual(outcome, .content(members))
        XCTAssertEqual(requestedIDs, [collectionID])
    }
}

private actor CollectionMembersLoaderStub: CollectionItemsLoading {
    private let members: [EntityThumbnail]
    private var requestedIDs: [UUID] = []

    init(members: [EntityThumbnail]) {
        self.members = members
    }

    func loadCollectionItems(collectionID: UUID) async throws -> [EntityThumbnail] {
        requestedIDs.append(collectionID)
        return members
    }

    func requestedCollectionIDs() -> [UUID] { requestedIDs }
}
