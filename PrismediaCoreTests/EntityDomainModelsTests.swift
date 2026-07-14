import XCTest

@testable import PrismediaCore

final class EntityDomainModelsTests: XCTestCase {
    func testBookDetailKeepsReaderDispatchFields() throws {
        let json = """
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "kind": "book",
              "title": "Native Book",
              "bookType": "comic",
              "format": "image-archive",
              "coverPageId": "22222222-2222-2222-2222-222222222222",
              "capabilities": [],
              "childrenByKind": [],
              "relationships": []
            }
            """

        let detail = try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))

        XCTAssertEqual(detail.bookType, "comic")
        XCTAssertEqual(detail.bookFormat, .imageArchive)
        XCTAssertEqual(detail.coverPageID, UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
    }

    func testThumbnailDecodesNativeStateAndPrefersDoubleDensityArtwork() throws {
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let parentID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let data = Data(
            """
            {
              "id": "\(entityID.uuidString)",
              "kind": "book-volume",
              "title": "Volume Two",
              "parentEntityId": "\(parentID.uuidString)",
              "parentKind": "book",
              "coverUrl": "/assets/original.jpg",
              "coverThumbUrl": "/assets/480.jpg",
              "coverThumb2xUrl": "/assets/960.jpg",
              "isWanted": true,
              "hasSourceMedia": false,
              "latestAcquisitionStatus": "downloading",
              "acquisitionStatuses": ["searching", "downloading"],
              "wantedStatus": "downloading",
              "rating": "4",
              "progress": "0.5",
              "resumeSeconds": "125.5",
              "playCount": "2"
            }
            """.utf8)

        let thumbnail = try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)

        XCTAssertEqual(thumbnail.bestCoverPath, "/assets/960.jpg")
        XCTAssertTrue(thumbnail.isWanted)
        XCTAssertFalse(thumbnail.hasSourceMedia)
        XCTAssertEqual(thumbnail.latestAcquisitionStatus?.rawValue, "downloading")
        XCTAssertEqual(thumbnail.acquisitionStatuses.map(\.rawValue), ["searching", "downloading"])
        XCTAssertEqual(thumbnail.wantedStatus?.rawValue, "downloading")
        XCTAssertEqual(thumbnail.rating, 4)
        XCTAssertEqual(thumbnail.progress, 0.5)
        XCTAssertEqual(thumbnail.resumeSeconds, 125.5)
        XCTAssertEqual(thumbnail.playCount, 2)

        let link = EntityLink(thumbnail: thumbnail)
        XCTAssertEqual(link.entityID, entityID)
        XCTAssertEqual(link.kind, .bookVolume)
        XCTAssertEqual(link.parentEntityID, parentID)
        XCTAssertEqual(link.parentKind, .book)
    }

    func testDetailDecodesKnownGroupsAndCapabilities() throws {
        let data = Data(
            """
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "kind": "video",
              "title": "Pilot",
              "parentEntityId": null,
              "sortOrder": "1",
              "hasSourceMedia": true,
              "capabilities": [
                { "kind": "description", "value": "The beginning." },
                {
                  "kind": "images",
                  "supportedKinds": ["poster", "backdrop"],
                  "items": [{ "kind": "poster", "path": "/assets/poster.jpg", "mimeType": "image/jpeg" }],
                  "thumbnailUrl": "/assets/480.jpg",
                  "thumbnail2xUrl": "/assets/960.jpg",
                  "coverUrl": "/assets/poster.jpg"
                },
                { "kind": "rating", "value": "4" }
              ],
              "childrenByKind": [
                {
                  "kind": "video",
                  "label": "Episodes",
                  "entities": [{
                    "id": "22222222-2222-2222-2222-222222222222",
                    "kind": "video",
                    "title": "Episode Two"
                  }]
                }
              ],
              "relationships": []
            }
            """.utf8)

        let detail = try PrismediaJSON.decoder().decode(EntityDetail.self, from: data)

        XCTAssertEqual(detail.sortOrder, 1)
        XCTAssertTrue(detail.hasSourceMedia)
        XCTAssertEqual(detail.childrenByKind.first?.entities.first?.title, "Episode Two")

        guard case .description(let description) = detail.capabilities[0] else {
            return XCTFail("Expected a description capability")
        }
        XCTAssertEqual(description.value, "The beginning.")

        guard case .images(let images) = detail.capabilities[1] else {
            return XCTFail("Expected an images capability")
        }
        XCTAssertEqual(images.thumbnail2xURL, "/assets/960.jpg")
        XCTAssertEqual(images.items.first?.kind, "poster")

        guard case .rating(let rating) = detail.capabilities[2] else {
            return XCTFail("Expected a rating capability")
        }
        XCTAssertEqual(rating.value, 4)
    }

    func testDetailRetainsUnknownCapabilityPayloads() throws {
        let data = Data(
            """
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "kind": "video",
              "title": "Future Video",
              "parentEntityId": null,
              "sortOrder": null,
              "capabilities": [{
                "kind": "future-vision",
                "enabled": true,
                "profile": { "name": "cinema", "level": 3 }
              }],
              "childrenByKind": [],
              "relationships": []
            }
            """.utf8)

        let detail = try PrismediaJSON.decoder().decode(EntityDetail.self, from: data)

        guard case .unknown(let capability) = detail.capabilities.first else {
            return XCTFail("Expected an unknown capability")
        }
        XCTAssertEqual(capability.kind, "future-vision")
        XCTAssertEqual(capability.fields["enabled"], .bool(true))
        XCTAssertEqual(
            capability.fields["profile"],
            .object(["name": .string("cinema"), "level": .integer(3)])
        )
    }

    func testMovieOwnedVideoLinksToTheMovieDetail() {
        let movieID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let videoID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let thumbnail = EntityThumbnail(
            id: videoID,
            kind: .video,
            title: "Movie File",
            parentEntityID: movieID,
            parentKind: .movie,
            progress: 0.25,
            resumeSeconds: 50
        )

        let link = EntityLink(thumbnail: thumbnail)

        XCTAssertEqual(link.entityID, movieID)
        XCTAssertEqual(link.kind, .movie)
        XCTAssertNil(link.parentEntityID)
        XCTAssertNil(link.parentKind)
        XCTAssertEqual(link.thumbnailPreview?.progress, 0.25)
        XCTAssertEqual(link.thumbnailPreview?.resumeSeconds, 50)
    }

    func testEpisodePlaybackLinksToItsSeasonAndPreservesTheEpisodeSource() {
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episodeID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let thumbnail = EntityThumbnail(
            id: episodeID,
            kind: .video,
            title: "Episode Seven",
            parentEntityID: seasonID,
            parentKind: .videoSeason,
            coverThumb2xURL: "/episodes/seven@2x.jpg",
            resumeSeconds: 420
        )

        let link = EntityLink(thumbnail: thumbnail, intent: .playback)

        XCTAssertEqual(link.entityID, seasonID)
        XCTAssertEqual(link.kind, .videoSeason)
        XCTAssertEqual(link.intent, .playback)
        XCTAssertEqual(link.sourceThumbnail, thumbnail)
        XCTAssertEqual(link.thumbnailPreview?.artworkPath, "/episodes/seven@2x.jpg")
        XCTAssertEqual(link.thumbnailPreview?.resumeSeconds, 420)
    }

    func testEpisodeDetailLinkRemainsOnTheEpisode() {
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episodeID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let thumbnail = EntityThumbnail(
            id: episodeID,
            kind: .video,
            title: "Episode Seven",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )

        let link = EntityLink(thumbnail: thumbnail, intent: .detail)

        XCTAssertEqual(link.entityID, episodeID)
        XCTAssertEqual(link.kind, .video)
        XCTAssertEqual(link.parentEntityID, seasonID)
        XCTAssertEqual(link.parentKind, .videoSeason)
    }

    func testEpisodePlaybackIdentityDistinguishesEpisodesWithinOneSeason() {
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let firstID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let secondID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let first = EntityThumbnail(
            id: firstID,
            kind: .video,
            title: "Episode One",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )
        let refreshedFirst = EntityThumbnail(
            id: firstID,
            kind: .video,
            title: "Episode One (Refreshed)",
            parentEntityID: seasonID,
            parentKind: .videoSeason,
            resumeSeconds: 120
        )
        let second = EntityThumbnail(
            id: secondID,
            kind: .video,
            title: "Episode Two",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )

        let firstLink = EntityLink(thumbnail: first, intent: .playback)
        let refreshedFirstLink = EntityLink(thumbnail: refreshedFirst, intent: .playback)
        let secondLink = EntityLink(thumbnail: second, intent: .playback)

        XCTAssertEqual(firstLink, refreshedFirstLink)
        XCTAssertNotEqual(firstLink, secondLink)
        XCTAssertEqual(Set([firstLink, secondLink]).count, 2)
    }

    func testAlbumOwnedTrackLinksToTheNativeAlbumDetail() {
        let albumID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let trackID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let thumbnail = EntityThumbnail(
            id: trackID,
            kind: .audioTrack,
            title: "Signals",
            parentEntityID: albumID,
            coverThumb2xURL: "/assets/grid-thumbs/signals@2x.jpg"
        )

        let link = EntityLink(thumbnail: thumbnail)

        XCTAssertEqual(link.entityID, albumID)
        XCTAssertEqual(link.kind, .audioLibrary)
        XCTAssertNil(link.parentEntityID)
        XCTAssertNil(link.parentKind)
        XCTAssertEqual(link.thumbnailPreview?.artworkPath, "/assets/grid-thumbs/signals@2x.jpg")
    }

    func testEntityLinkCarriesThumbnailPreviewWithoutChangingNavigationIdentity() {
        let id = UUID()
        let first = EntityThumbnail(
            id: id,
            kind: .audioLibrary,
            title: "Smoke + Mirrors",
            coverThumb2xURL: "/assets/grid-thumbs/smoke@2x.jpg"
        )
        let updated = EntityThumbnail(
            id: id,
            kind: .audioLibrary,
            title: "Smoke + Mirrors",
            coverThumb2xURL: "/assets/grid-thumbs/smoke-new@2x.jpg",
            rating: 5
        )

        let firstLink = EntityLink(thumbnail: first, previewSubtitle: "Imagine Dragons")
        let updatedLink = EntityLink(thumbnail: updated, previewSubtitle: "Imagine Dragons")

        XCTAssertEqual(firstLink.thumbnailPreview?.artworkPath, "/assets/grid-thumbs/smoke@2x.jpg")
        XCTAssertEqual(firstLink.previewSubtitle, "Imagine Dragons")
        XCTAssertEqual(firstLink, updatedLink)
        XCTAssertEqual(Set([firstLink, updatedLink]).count, 1)
    }

    func testEntityLinkIntentParticipatesInStableDestinationIdentity() {
        let id = UUID()

        let detail = EntityLink(entityID: id, kind: .video, intent: .detail)
        let playback = EntityLink(entityID: id, kind: .video, intent: .playback)

        XCTAssertNotEqual(detail, playback)
    }

    func testImageMediaSequencePreservesOrderAndUsesFiniteBoundaries() {
        let first = EntityThumbnail(id: UUID(), kind: .image, title: "First")
        let second = EntityThumbnail(id: UUID(), kind: .image, title: "Second")
        let ignored = EntityThumbnail(id: UUID(), kind: .gallery, title: "Gallery")
        let sequence = EntityMediaSequence(items: [first, ignored, second, first])

        XCTAssertEqual(sequence.items, [first, second])
        XCTAssertNil(sequence.previous(to: first.id))
        XCTAssertEqual(sequence.next(to: first.id), second)
        XCTAssertEqual(sequence.previous(to: second.id), first)
        XCTAssertNil(sequence.next(to: second.id))
    }

    func testImageMediaSequenceDoesNotChangeEntityLinkNavigationIdentity() {
        let image = EntityThumbnail(id: UUID(), kind: .image, title: "Photo")
        let neighbor = EntityThumbnail(id: UUID(), kind: .image, title: "Neighbor")
        let first = EntityLink(thumbnail: image)
        let sequenced = EntityLink(
            thumbnail: image,
            mediaSequence: EntityMediaSequence(items: [image, neighbor])
        )

        XCTAssertEqual(first, sequenced)
        XCTAssertEqual(sequenced.mediaSequence?.items, [image, neighbor])
    }

}
