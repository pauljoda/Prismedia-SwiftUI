import XCTest

@testable import PrismediaCore

final class EntityThumbnailPresentationTests: XCTestCase {
    func testThumbnailDecodesConciseDescriptionFromExistingServerNames() throws {
        let description = try decodeThumbnail(descriptionMember: #""description":"A description.""#)
        let overview = try decodeThumbnail(descriptionMember: #""overview":"An overview.""#)
        let summary = try decodeThumbnail(descriptionMember: #""summary":"A summary.""#)

        XCTAssertEqual(description.summary, "A description.")
        XCTAssertEqual(overview.summary, "An overview.")
        XCTAssertEqual(summary.summary, "A summary.")
    }

    func testThumbnailDecodesCanonicalSubtitle() throws {
        let data = Data(
            #"{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","kind":"video-season","title":"Season 1","subtitle":"Example Series"}"#.utf8
        )

        let thumbnail = try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)

        XCTAssertEqual(thumbnail.subtitle, "Example Series")
    }

    func testOverlayPolicyPlacesPositionStatusSafetyAndRatingInCanonicalCorners() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Wanted Video",
            parentKind: .videoSeason,
            sortOrder: 1,
            rating: 4,
            isNsfw: true,
            isWanted: true,
            wantedStatus: AcquisitionStatus(rawValue: "downloading")
        )

        let policy = EntityThumbnailOverlayPolicy(item: item)

        XCTAssertEqual(policy.topTrailing.map(\.kind), [.wanted])
        XCTAssertEqual(policy.topTrailing.first?.label, "Downloading")
        XCTAssertEqual(policy.bottomLeading.map(\.kind), [.position])
        XCTAssertEqual(policy.bottomLeading.first?.label, "E1")
        XCTAssertEqual(policy.bottomTrailing.map(\.kind), [.nsfw, .rating])
        XCTAssertEqual(policy.bottomTrailing.last?.label, "4")
    }

    func testReleaseGatedThumbnailUsesTheServerAcquisitionStatus() {
        let item = EntityThumbnail(
            id: UUID(),
            kind: .movie,
            title: "Future Movie",
            isWanted: true,
            wantedStatus: AcquisitionStatus(rawValue: "waiting-for-release")
        )

        let badge = EntityThumbnailOverlayPolicy(item: item).topTrailing.first

        XCTAssertEqual(badge?.label, "Waiting")
        XCTAssertEqual(badge?.systemImage, "calendar.badge.clock")
        XCTAssertEqual(badge?.tone, .queued)
    }

    func testOverlayPolicyOmitsZeroRating() {
        let item = EntityThumbnail(id: UUID(), kind: .movie, title: "Unrated", rating: 0)

        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: item).bottomTrailing.isEmpty)
    }

    func testVideoListModeReusesTheRailCardWhileOtherKindsKeepListPresentation() {
        XCTAssertEqual(EntityGridDisplayMode.list.thumbnailLayout(for: .video), .rail)
        XCTAssertEqual(EntityGridDisplayMode.list.thumbnailLayout(for: .movie), .list)
        XCTAssertEqual(EntityGridDisplayMode.grid.thumbnailLayout(for: .video), .grid)
    }

    private func decodeThumbnail(descriptionMember: String) throws -> EntityThumbnail {
        let data = Data(
            """
            {
              "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
              "kind": "video",
              "title": "Episode",
              \(descriptionMember)
            }
            """.utf8
        )
        return try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)
    }
}
