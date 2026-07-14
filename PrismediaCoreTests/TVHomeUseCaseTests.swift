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

    func testLoadRequestsEveryWebsiteParityShelf() async {
        let loader = TVHomeLoaderStub()
        let useCase = TVHomeUseCase(loader: loader)

        _ = await useCase.load()

        let requestedIDs = await loader.requestedShelfIDs()
        XCTAssertEqual(Set(requestedIDs), Set(TVAppCatalog.homeShelves.map(\.id)))
    }
}

private actor TVHomeLoaderStub: TVHomeLoading {
    private let itemsByShelfID: [String: [EntityThumbnail]]
    private let failedShelfIDs: Set<String>
    private var requestedIDs: [String] = []

    init(
        itemsByShelfID: [String: [EntityThumbnail]] = [:],
        failedShelfIDs: Set<String> = []
    ) {
        self.itemsByShelfID = itemsByShelfID
        self.failedShelfIDs = failedShelfIDs
    }

    func load(shelf: TVHomeShelf) async throws -> [EntityThumbnail] {
        requestedIDs.append(shelf.id)
        if failedShelfIDs.contains(shelf.id) { throw TVHomeLoaderStubError.failed }
        return itemsByShelfID[shelf.id] ?? []
    }

    func requestedShelfIDs() -> [String] {
        requestedIDs
    }
}

private enum TVHomeLoaderStubError: Error {
    case failed
}
