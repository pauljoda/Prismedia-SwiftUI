import XCTest

@testable import PrismediaCore

final class FavoritesServiceTests: XCTestCase {
    @MainActor
    func testFavoritesOverviewLoadsEveryKindInOneBoundedRequest() async {
        let book = favoriteItem(1, kind: .book, title: "Book")
        let movie = favoriteItem(2, kind: .movie, title: "Movie")
        let loader = FavoritesLoaderStub(items: [book, movie])

        let snapshot = await FavoritesService(loader: loader).load()

        XCTAssertEqual(snapshot.sections.first { $0.definition.kind == .book }?.items, [book])
        XCTAssertEqual(snapshot.sections.first { $0.definition.kind == .movie }?.items, [movie])
        let requests = await loader.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.query.kinds, FavoritesCatalog.kinds)
        XCTAssertEqual(requests.first?.query.favorite, true)
        XCTAssertEqual(requests.first?.limit, FavoritesCatalog.overviewLimit)
    }
}

private actor FavoritesLoaderStub: FavoritesLoading {
    struct Request: Sendable {
        let query: EntityListQuery
        let limit: Int
    }

    let items: [EntityThumbnail]
    private(set) var requests: [Request] = []

    init(items: [EntityThumbnail]) {
        self.items = items
    }

    func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
        requests.append(Request(query: query, limit: limit))
        return EntityListResponse(items: Array(items.prefix(limit)))
    }
}

private func favoriteItem(_ value: Int, kind: EntityKind, title: String) -> EntityThumbnail {
    EntityThumbnail(
        id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!,
        kind: kind,
        title: title
    )
}
