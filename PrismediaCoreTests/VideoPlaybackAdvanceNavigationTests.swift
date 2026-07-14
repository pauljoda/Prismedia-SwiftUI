import XCTest

@testable import PrismediaCore

@MainActor
final class VideoPlaybackAdvanceNavigationTests: XCTestCase {
    func testInlineAdvanceReturnsDestinationImmediately() {
        var navigation = VideoPlaybackAdvanceNavigation()
        let link = EntityLink(entityID: UUID(), kind: .video)

        let destination = navigation.receive(link, isFullscreen: false)

        XCTAssertEqual(destination, link)
        XCTAssertFalse(navigation.fullscreenDidDismiss())
    }

    func testFullscreenAdvanceIsConsumedWithoutReturningANavigationDestination() {
        var navigation = VideoPlaybackAdvanceNavigation()
        let second = EntityLink(entityID: UUID(), kind: .video)
        let third = EntityLink(entityID: UUID(), kind: .video)

        XCTAssertNil(navigation.receive(second, isFullscreen: true))
        XCTAssertNil(navigation.receive(third, isFullscreen: true))

        XCTAssertTrue(navigation.fullscreenDidDismiss())
        XCTAssertFalse(navigation.fullscreenDidDismiss())
    }

    func testPageResetWhileParentLoadIsPendingPreventsOffPageEpisodeResolution() async throws {
        let parentID = UUID(uuidString: "10101010-2020-3030-4040-505050505050")!
        let currentID = UUID(uuidString: "11111111-2020-3030-4040-505050505050")!
        let nextID = UUID(uuidString: "12121212-2020-3030-4040-505050505050")!
        let current = try videoDetail(id: currentID, parentID: parentID, title: "Episode One")
        let next = try videoDetail(id: nextID, parentID: parentID, title: "Episode Two")
        let parent = try parentDetail(id: parentID, currentID: currentID, nextID: nextID)
        let loader = DelayedAdvanceDetailLoader(
            parentID: parentID,
            parent: parent,
            nextID: nextID,
            next: next
        )
        let preparation = VideoPlaybackPreparationCoordinator()
        let lifecycle = preparation.lifecycleToken()
        let resolver = VideoPlaybackAdvanceResolver(loader: loader)

        let task = Task {
            await resolver.resolveNext(
                after: current,
                lifecycleIsCurrent: { preparation.isCurrent(lifecycle) }
            )
        }
        await loader.waitUntilParentRequested()

        preparation.reset()
        await loader.releaseParent()
        let resolution = await task.value
        let loadedIDs = await loader.loadedIDs

        XCTAssertNil(resolution)
        XCTAssertEqual(loadedIDs, [parentID])
    }

    private func videoDetail(id: UUID, parentID: UUID, title: String) throws -> EntityDetail {
        try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"\(id.uuidString)","kind":"video","title":"\(title)","parentEntityId":"\(parentID.uuidString)","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],"relationships":[]}
                """.utf8))
    }

    private func parentDetail(id: UUID, currentID: UUID, nextID: UUID) throws -> EntityDetail {
        try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"\(id.uuidString)","kind":"video-season","title":"Season One","hasSourceMedia":false,"capabilities":[],"childrenByKind":[{"kind":"video","label":"Episodes","entities":[{"id":"\(currentID.uuidString)","kind":"video","title":"Episode One","sortOrder":1},{"id":"\(nextID.uuidString)","kind":"video","title":"Episode Two","sortOrder":2}]}],"relationships":[]}
                """.utf8))
    }
}

private actor DelayedAdvanceDetailLoader: EntityDetailLoading {
    private(set) var loadedIDs: [UUID] = []
    private let parentID: UUID
    private let parent: EntityDetail
    private let nextID: UUID
    private let next: EntityDetail
    private var parentRequested = false
    private var parentRequestWaiters: [CheckedContinuation<Void, Never>] = []
    private var parentRelease: CheckedContinuation<Void, Never>?

    init(
        parentID: UUID,
        parent: EntityDetail,
        nextID: UUID,
        next: EntityDetail
    ) {
        self.parentID = parentID
        self.parent = parent
        self.nextID = nextID
        self.next = next
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        loadedIDs.append(id)
        if id == parentID {
            parentRequested = true
            for waiter in parentRequestWaiters {
                waiter.resume()
            }
            parentRequestWaiters = []
            await withCheckedContinuation { parentRelease = $0 }
            return parent
        }
        if id == nextID { return next }
        throw DelayedAdvanceTestError.unexpectedID(id)
    }

    func waitUntilParentRequested() async {
        guard !parentRequested else { return }
        await withCheckedContinuation { parentRequestWaiters.append($0) }
    }

    func releaseParent() {
        parentRelease?.resume()
        parentRelease = nil
    }
}

private enum DelayedAdvanceTestError: Error {
    case unexpectedID(UUID)
}
