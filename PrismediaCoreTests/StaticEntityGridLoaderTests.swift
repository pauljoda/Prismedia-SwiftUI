import XCTest

@testable import PrismediaCore

final class StaticEntityGridLoaderTests: XCTestCase {
    @MainActor
    func testStaticGalleryLoaderRetainsVisibleNsfwImagesWhenTheAppAllowsThem() async throws {
        let image = EntityThumbnail(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            kind: .image,
            title: "Visible Gallery Image",
            isNsfw: true
        )
        let configuration = EntityGridConfiguration(
            title: "Images",
            query: EntityListQuery(kind: .image)
        )
        var snapshot = EntityGridSnapshot(configuration: configuration)
        let request = snapshot.beginFirstPage(
            configuration: configuration,
            preservingContent: false
        )
        let service = EntityGridService(
            loader: StaticEntityGridLoader(items: [image], allowsNsfwContent: true)
        )

        let page = try await service.loadFirstPage(request)

        XCTAssertEqual(page.items, [image])
        XCTAssertEqual(page.totalCount, 1)
    }

    func testStaticLoaderAppliesGallerySearchFiltersAndTitleSort() async throws {
        let favorite = thumbnail(id: 1, title: "Amber", isFavorite: true)
        let otherFavorite = thumbnail(id: 2, title: "Azure", isFavorite: true)
        let ordinary = thumbnail(id: 3, title: "Amber Draft", isFavorite: false)
        let loader = StaticEntityGridLoader(items: [ordinary, otherFavorite, favorite])

        let response = try await loader.load(
            query: EntityListQuery(kind: .image, sort: "title", sortDescending: false, favorite: true),
            limit: 48,
            search: "am",
            cursor: nil
        )

        XCTAssertEqual(response.items, [favorite])
        XCTAssertEqual(response.totalCount, 1)
        XCTAssertNil(response.nextCursor)
    }

    func testStaticLoaderPagesTheFilteredSequenceWithOpaqueOffsets() async throws {
        let items = (1...3).map { thumbnail(id: $0, title: "Image \($0)", isFavorite: false) }
        let loader = StaticEntityGridLoader(items: items)

        let first = try await loader.load(
            query: EntityListQuery(kind: .image),
            limit: 2,
            search: nil,
            cursor: nil
        )
        let second = try await loader.load(
            query: EntityListQuery(kind: .image),
            limit: 2,
            search: nil,
            cursor: first.nextCursor
        )

        XCTAssertEqual(first.items, Array(items.prefix(2)))
        XCTAssertEqual(first.nextCursor, "2")
        XCTAssertEqual(second.items, [items[2]])
        XCTAssertNil(second.nextCursor)
        XCTAssertEqual(second.totalCount, 3)
    }

    func testStaticLoaderDefaultsChildSequenceToAscending() async throws {
        let tenth = thumbnail(
            id: 10,
            kind: .video,
            title: "Episode Ten",
            isFavorite: false,
            sortOrder: 10
        )
        let first = thumbnail(
            id: 1,
            kind: .video,
            title: "Episode One",
            isFavorite: false,
            sortOrder: 1
        )
        let loader = StaticEntityGridLoader(items: [tenth, first])

        let response = try await loader.load(
            query: EntityListQuery(kind: .video, sort: "added"),
            limit: 48,
            search: nil,
            cursor: nil
        )

        XCTAssertEqual(response.items.map(\.sortOrder), [1, 10])
    }

    private func thumbnail(
        id: Int,
        kind: EntityKind = .image,
        title: String,
        isFavorite: Bool,
        sortOrder: Int? = nil
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            kind: kind,
            title: title,
            sortOrder: sortOrder,
            isFavorite: isFavorite
        )
    }
}
