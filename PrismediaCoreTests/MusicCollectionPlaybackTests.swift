import XCTest

@testable import PrismediaCore

final class MusicCollectionQueueLoaderTests: XCTestCase {
    func testPreservesArtistsAcrossLooseTrackAlbumAndArtistCollectionMembers() async throws {
        let looseArtist = thumbnail("01000000-0000-0000-0000-000000000001", .musicArtist, "Loose Artist")
        let looseAlbum = thumbnail(
            "01000000-0000-0000-0000-000000000002",
            .audioLibrary,
            "Loose Album",
            parent: looseArtist
        )
        let looseTrack = thumbnail(
            "01000000-0000-0000-0000-000000000003",
            .audioTrack,
            "Loose Track",
            parent: looseAlbum
        )
        let albumArtist = thumbnail("02000000-0000-0000-0000-000000000001", .musicArtist, "Album Artist")
        let album = thumbnail(
            "02000000-0000-0000-0000-000000000002",
            .audioLibrary,
            "Collection Album",
            parent: albumArtist
        )
        let albumTrack = thumbnail(
            "02000000-0000-0000-0000-000000000003",
            .audioTrack,
            "Album Track",
            parent: album
        )
        let artist = thumbnail("03000000-0000-0000-0000-000000000001", .musicArtist, "Collection Artist")
        let artistAlbum = thumbnail(
            "03000000-0000-0000-0000-000000000002",
            .audioLibrary,
            "Artist Album",
            parent: artist
        )
        let artistTrack = thumbnail(
            "03000000-0000-0000-0000-000000000003",
            .audioTrack,
            "Artist Track",
            parent: artistAlbum
        )
        let collectionID = UUID(uuidString: "04000000-0000-0000-0000-000000000001")!
        let items = MusicCollectionItemsLoaderStub(itemsByCollection: [
            collectionID: [looseTrack, album, artist]
        ])
        let details = MusicCollectionDetailLoaderStub(detailsByID: [
            looseArtist.id: detail(looseArtist),
            looseAlbum.id: detail(
                looseAlbum,
                children: [
                    EntityGroup(kind: .audioTrack, label: "Tracks", entities: [looseTrack], code: nil)
                ]),
            albumArtist.id: detail(albumArtist),
            album.id: detail(
                album,
                children: [
                    EntityGroup(kind: .audioTrack, label: "Tracks", entities: [albumTrack], code: nil)
                ]),
            artist.id: detail(
                artist,
                children: [
                    EntityGroup(kind: .audioLibrary, label: "Albums", entities: [artistAlbum], code: nil)
                ]),
            artistAlbum.id: detail(
                artistAlbum,
                children: [
                    EntityGroup(kind: .audioTrack, label: "Tracks", entities: [artistTrack], code: nil)
                ]),
        ])

        let snapshot = try await MusicCollectionQueueLoader(
            collectionItemsLoader: items,
            detailLoader: details
        ).load(collectionID: collectionID)

        XCTAssertEqual(snapshot.tracks.map(\.artist), ["Loose Artist", "Album Artist", "Collection Artist"])
        XCTAssertEqual(snapshot.tracks.map(\.album), ["Loose Album", "Collection Album", "Artist Album"])
    }

    func testExpandsEveryAudioMemberInCollectionOrderAndGroupsBySourceMember() async throws {
        let looseTrack = thumbnail("10000000-0000-0000-0000-000000000001", .audioTrack, "Loose Track")
        let album = thumbnail("20000000-0000-0000-0000-000000000001", .audioLibrary, "Album Source")
        let artist = thumbnail("30000000-0000-0000-0000-000000000001", .musicArtist, "Artist Source")
        let albumTrackOne = thumbnail("40000000-0000-0000-0000-000000000001", .audioTrack, "Album One", order: 1)
        let albumTrackTwo = thumbnail("40000000-0000-0000-0000-000000000002", .audioTrack, "Album Two", order: 2)
        let nestedAlbum = thumbnail("50000000-0000-0000-0000-000000000001", .audioLibrary, "Nested Album", order: 3)
        let nestedTrack = thumbnail("60000000-0000-0000-0000-000000000001", .audioTrack, "Nested Track", order: 1)
        let artistAlbum = thumbnail("70000000-0000-0000-0000-000000000001", .audioLibrary, "Artist Album", order: 1)
        let directArtistTrack = thumbnail(
            "70000000-0000-0000-0000-000000000002", .audioTrack, "Artist Single", order: 1)
        let artistTrack = thumbnail("80000000-0000-0000-0000-000000000001", .audioTrack, "Artist Track", order: 1)
        let collectionID = UUID(uuidString: "90000000-0000-0000-0000-000000000001")!

        let items = MusicCollectionItemsLoaderStub(itemsByCollection: [
            collectionID: [looseTrack, album, artist]
        ])
        let details = MusicCollectionDetailLoaderStub(detailsByID: [
            album.id: detail(
                album,
                children: [
                    EntityGroup(
                        kind: .audioTrack, label: "Tracks", entities: [albumTrackOne, albumTrackTwo], code: nil),
                    EntityGroup(kind: .audioLibrary, label: "Albums", entities: [nestedAlbum], code: nil),
                ]),
            nestedAlbum.id: detail(
                nestedAlbum,
                children: [
                    EntityGroup(kind: .audioTrack, label: "Tracks", entities: [nestedTrack], code: nil)
                ]),
            artist.id: detail(
                artist,
                children: [
                    EntityGroup(kind: .audioTrack, label: "Tracks", entities: [directArtistTrack], code: nil),
                    EntityGroup(kind: .audioLibrary, label: "Albums", entities: [artistAlbum], code: nil),
                ]),
            artistAlbum.id: detail(
                artistAlbum,
                children: [
                    EntityGroup(kind: .audioTrack, label: "Tracks", entities: [artistTrack], code: nil)
                ]),
        ])

        let snapshot = try await MusicCollectionQueueLoader(
            collectionItemsLoader: items,
            detailLoader: details
        ).load(collectionID: collectionID)

        XCTAssertEqual(
            snapshot.tracks.map(\.id),
            [
                looseTrack.id, albumTrackOne.id, albumTrackTwo.id, nestedTrack.id,
                directArtistTrack.id, artistTrack.id,
            ]
        )
        XCTAssertEqual(snapshot.sections.map(\.title), ["Loose Track", "Album Source", "Artist Source"])
        XCTAssertEqual(
            snapshot.sections.map { $0.tracks.map(\.id) },
            [
                [looseTrack.id],
                [albumTrackOne.id, albumTrackTwo.id, nestedTrack.id],
                [directArtistTrack.id, artistTrack.id],
            ])
    }

    func testSkipsNonAudioMembersWithoutChangingAudioOrder() async throws {
        let collectionID = UUID()
        let movie = thumbnail(UUID().uuidString, .movie, "Movie")
        let first = thumbnail(UUID().uuidString, .audioTrack, "First")
        let book = thumbnail(UUID().uuidString, .book, "Book")
        let second = thumbnail(UUID().uuidString, .audioTrack, "Second")
        let items = MusicCollectionItemsLoaderStub(itemsByCollection: [
            collectionID: [movie, first, book, second]
        ])

        let snapshot = try await MusicCollectionQueueLoader(
            collectionItemsLoader: items,
            detailLoader: MusicCollectionDetailLoaderStub(detailsByID: [:])
        ).load(collectionID: collectionID)

        XCTAssertEqual(snapshot.tracks.map(\.id), [first.id, second.id])
        XCTAssertEqual(snapshot.sections.map(\.title), ["First", "Second"])
    }

    private func thumbnail(
        _ id: String,
        _ kind: EntityKind,
        _ title: String,
        order: Int? = nil,
        parent: EntityThumbnail? = nil
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: id)!,
            kind: kind,
            title: title,
            parentEntityID: parent?.id,
            parentKind: parent?.kind,
            sortOrder: order
        )
    }

    private func detail(_ thumbnail: EntityThumbnail, children: [EntityGroup] = []) -> EntityDetail {
        EntityDetail(
            id: thumbnail.id,
            kind: thumbnail.kind,
            title: thumbnail.title,
            parentEntityID: thumbnail.parentEntityID,
            sortOrder: thumbnail.sortOrder,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: children,
            relationships: []
        )
    }
}

final class MusicCollectionCatalogLoaderTests: XCTestCase {
    func testReturnsOnlyCollectionsWithAudioCapableMembersInCatalogOrder() async throws {
        let videoCollection = EntityThumbnail(id: UUID(), kind: .collection, title: "Video")
        let albumCollection = EntityThumbnail(id: UUID(), kind: .collection, title: "Albums")
        let artistCollection = EntityThumbnail(id: UUID(), kind: .collection, title: "Artists")
        let catalog = MusicCollectionCatalogPageLoaderStub(items: [
            videoCollection, albumCollection, artistCollection,
        ])
        let items = MusicCollectionItemsLoaderStub(itemsByCollection: [
            videoCollection.id: [EntityThumbnail(id: UUID(), kind: .movie, title: "Movie")],
            albumCollection.id: [EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Album")],
            artistCollection.id: [EntityThumbnail(id: UUID(), kind: .musicArtist, title: "Artist")],
        ])
        let loader = MusicCollectionCatalogLoader(
            catalogLoader: catalog,
            collectionItemsLoader: items,
            membershipConcurrency: 2
        )

        let response = try await loader.load(
            query: EntityListQuery(kind: .collection, sort: "added"),
            limit: 48,
            search: nil,
            cursor: nil
        )

        XCTAssertEqual(response.items.map(\.id), [albumCollection.id, artistCollection.id])
        XCTAssertEqual(response.totalCount, 2)
        XCTAssertNil(response.nextCursor)
        let requestedIDs = await items.requestedCollectionIDs()
        XCTAssertEqual(Set(requestedIDs), Set([videoCollection.id, albumCollection.id, artistCollection.id]))
    }
}

private actor MusicCollectionItemsLoaderStub: CollectionItemsLoading {
    private let itemsByCollection: [UUID: [EntityThumbnail]]
    private var requestedIDs: [UUID] = []

    init(itemsByCollection: [UUID: [EntityThumbnail]]) {
        self.itemsByCollection = itemsByCollection
    }

    func loadCollectionItems(collectionID: UUID) async throws -> [EntityThumbnail] {
        requestedIDs.append(collectionID)
        return itemsByCollection[collectionID, default: []]
    }

    func requestedCollectionIDs() -> [UUID] { requestedIDs }
}

private actor MusicCollectionDetailLoaderStub: EntityDetailLoading {
    private let detailsByID: [UUID: EntityDetail]

    init(detailsByID: [UUID: EntityDetail]) {
        self.detailsByID = detailsByID
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let detail = detailsByID[id] else { throw MusicCollectionTestError.missingDetail }
        return detail
    }
}

private struct MusicCollectionCatalogPageLoaderStub: EntityGridLoading {
    let items: [EntityThumbnail]
    let allowsNsfwContent = false

    func load(
        query: EntityListQuery,
        limit: Int,
        search: String?,
        cursor: String?
    ) async throws -> EntityListResponse {
        EntityListResponse(items: items, totalCount: items.count)
    }
}

private enum MusicCollectionTestError: Error {
    case missingDetail
}
