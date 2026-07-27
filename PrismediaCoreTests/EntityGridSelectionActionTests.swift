import XCTest

@testable import PrismediaCore

final class EntityGridSelectionActionTests: XCTestCase {
    func testSelectionCanStartActiveForSelectionFirstWorkflows() {
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        var selection = EntityGridSelectionState(isActive: true)

        selection.toggle(entityID)

        XCTAssertTrue(selection.isActive)
        XCTAssertEqual(selection.selectedIDs, [entityID])
    }

    func testSelectionUsesStableEntityIDsAcrossPaginationAndReconcilesAfterRefresh() {
        let firstPageID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondPageID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        var selection = EntityGridSelectionState()

        selection.enter()
        selection.toggle(firstPageID)
        selection.toggle(secondPageID)

        XCTAssertTrue(selection.isActive)
        XCTAssertEqual(selection.selectedIDs, [firstPageID, secondPageID])

        selection.reconcile(withAvailableIDs: [secondPageID])

        XCTAssertEqual(selection.selectedIDs, [secondPageID])
        XCTAssertTrue(selection.isActive)
    }

    func testSelectAllVisibleAndExitHaveExplicitClearSemantics() {
        let ids = [
            UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        ]
        var selection = EntityGridSelectionState()

        selection.enter()
        selection.selectAllVisible(ids)
        XCTAssertEqual(selection.selectedIDs, Set(ids))

        selection.clear()
        XCTAssertTrue(selection.selectedIDs.isEmpty)
        XCTAssertTrue(selection.isActive)

        selection.selectAllVisible(ids)
        selection.exit()
        XCTAssertFalse(selection.isActive)
        XCTAssertTrue(selection.selectedIDs.isEmpty)
    }

    func testLibraryPolicyFiltersCollectionEligibilityAndWantedActionForMixedSelection() {
        let movie = thumbnail(id: "11111111-1111-1111-1111-111111111111", kind: .movie)
        let tag = thumbnail(id: "22222222-2222-2222-2222-222222222222", kind: .tag)
        let wanted = thumbnail(
            id: "33333333-3333-3333-3333-333333333333",
            kind: .book,
            isWanted: true
        )
        let policy = EntityGridActionPolicy.library(user: user(allowSfw: true, allowNsfw: true))

        XCTAssertEqual(
            policy.collectionReferences(in: [movie, tag, wanted]).map(\.entityID),
            [movie.id, wanted.id]
        )
        XCTAssertTrue(policy.availableBuiltInActions(for: [wanted]).contains(.removeWanted))
        XCTAssertFalse(policy.availableBuiltInActions(for: [movie, wanted]).contains(.removeWanted))
    }

    func testNsfwMutationRequiresRouteCapabilityAndBothVisibilityPermissions() {
        let item = thumbnail(id: "11111111-1111-1111-1111-111111111111", kind: .movie)

        let eligible = EntityGridActionPolicy.library(
            user: user(allowSfw: true, allowNsfw: true)
        )
        let sfwOnly = EntityGridActionPolicy.library(
            user: user(allowSfw: true, allowNsfw: false)
        )

        XCTAssertTrue(eligible.availableBuiltInActions(for: [item]).contains(.toggleNsfw))
        XCTAssertFalse(sfwOnly.availableBuiltInActions(for: [item]).contains(.toggleNsfw))
    }

    @MainActor
    func testFlagMutationReportsPartialFailureWithoutClearingFailedIdentity() async {
        let successful = thumbnail(id: "11111111-1111-1111-1111-111111111111", kind: .movie)
        let failed = thumbnail(id: "22222222-2222-2222-2222-222222222222", kind: .movie)
        let mutations = EntityGridMutationServiceStub(failingFlagIDs: [failed.id])
        let service = EntityGridActionService(mutations: mutations)

        let result = await service.markNsfw(true, items: [successful, failed])

        XCTAssertEqual(result.succeededIDs, [successful.id])
        XCTAssertEqual(result.failures.map(\.entityID), [failed.id])
        let flaggedIDs = await mutations.flaggedIDs()
        XCTAssertEqual(flaggedIDs, [successful.id, failed.id])
    }

    @MainActor
    func testWantedRemovalKeepsServerFailureAssociatedWithEntity() async {
        let successful = thumbnail(
            id: "11111111-1111-1111-1111-111111111111",
            kind: .movie,
            isWanted: true
        )
        let failed = thumbnail(
            id: "22222222-2222-2222-2222-222222222222",
            kind: .movie,
            isWanted: true
        )
        let mutations = EntityGridMutationServiceStub(failingWantedIDs: [failed.id])
        let service = EntityGridActionService(mutations: mutations)

        let result = await service.removeWanted(items: [successful, failed])

        XCTAssertEqual(result.succeededIDs, [successful.id])
        XCTAssertEqual(result.failures.map(\.entityID), [failed.id])
    }

    func testRoutePresentationUsesMediaDefaultsAndRejectsStaleSavedLayouts() {
        let images = EntityGridConfiguration.library(
            destinationID: "images",
            title: "Images",
            query: EntityListQuery(kind: .image)
        )
        let videos = EntityGridConfiguration.library(
            destinationID: "videos",
            title: "Videos",
            query: EntityListQuery(kind: .video)
        )
        let movies = EntityGridConfiguration.library(
            destinationID: "movies",
            title: "Movies",
            query: EntityListQuery(kind: .movie)
        )

        XCTAssertEqual(images.defaultDisplayMode, .wall)
        XCTAssertEqual(images.availableDisplayModes, [.wall, .grid, .list, .feed])
        XCTAssertEqual(images.resolvedDisplayMode(restoring: .feed), .feed)
        XCTAssertEqual(videos.defaultDisplayMode, .wall)
        XCTAssertEqual(videos.availableDisplayModes, [.wall, .grid, .list, .feed])
        XCTAssertEqual(movies.availableDisplayModes, [.grid, .list])
        XCTAssertEqual(movies.resolvedDisplayMode(restoring: .feed), .grid)
        XCTAssertEqual(images.emptyTitle, "No Images")
        XCTAssertTrue(images.emptyDescription.contains("library root"))
    }

    private func thumbnail(
        id: String,
        kind: EntityKind,
        isNsfw: Bool = false,
        isWanted: Bool = false
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: id)!,
            kind: kind,
            title: kind.displayLabel,
            isNsfw: isNsfw,
            isWanted: isWanted
        )
    }

    private func user(allowSfw: Bool, allowNsfw: Bool) -> UserAccount {
        UserAccount(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            username: "member",
            displayName: "Member",
            role: .member,
            allowSfw: allowSfw,
            allowNsfw: allowNsfw
        )
    }
}
