import XCTest

@testable import PrismediaCore

@MainActor
final class TVHomeUseCaseTests: XCTestCase {
    func testOneFailedShelfDoesNotHideTheOtherHomeContent() async {
        let hero = PrismediaPreviewData.videos[0]
        let movie = PrismediaPreviewData.videos[1]
        let loader = TVHomeLoaderStub(
            itemsByShelfID: [
                "in-progress": [hero],
                "movies": [movie],
            ],
            failedShelfIDs: ["recently-watched"]
        )
        let useCase = TVHomeUseCase(loader: loader)

        let result = await useCase.load()

        XCTAssertEqual(result.snapshot.hero?.id, hero.id)
        XCTAssertEqual(result.snapshot.items(for: "movies").map(\.id), [movie.id])
        XCTAssertEqual(result.failedShelfIDs, ["recently-watched"])
    }
}

private actor TVHomeLoaderStub: TVHomeLoading {
    private let itemsByShelfID: [String: [EntityThumbnail]]
    private let failedShelfIDs: Set<String>

    init(
        itemsByShelfID: [String: [EntityThumbnail]] = [:],
        failedShelfIDs: Set<String> = []
    ) {
        self.itemsByShelfID = itemsByShelfID
        self.failedShelfIDs = failedShelfIDs
    }

    func load(shelf: TVHomeShelf) async throws -> [EntityThumbnail] {
        if failedShelfIDs.contains(shelf.id) { throw TVHomeLoaderStubError.failed }
        return itemsByShelfID[shelf.id] ?? []
    }
}

private enum TVHomeLoaderStubError: Error {
    case failed
}
