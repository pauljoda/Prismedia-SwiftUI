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

    func testThumbnailDecodesAndPresentsEpisodesThatShareOneSource() throws {
        let data = Data(
            #"{"id":"22222222-2222-2222-2222-222222222222","kind":"video-episode","title":"Friends Like","sortOrder":2,"sharedSourceEpisodes":[{"id":"22222222-2222-2222-2222-222222222222","title":"Friends Like","seasonNumber":7,"episodeNumber":2},{"id":"33333333-3333-3333-3333-333333333333","title":"Space Restaurant","seasonNumber":7,"episodeNumber":3}]}"#.utf8
        )

        let thumbnail = try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)

        XCTAssertEqual(thumbnail.sharedSourceEpisodes.map(\.episodeNumber), [2, 3])
        XCTAssertEqual(thumbnail.displayTitle, "Friends Like + Space Restaurant")
        XCTAssertEqual(
            EntityThumbnailOverlayPolicy(item: thumbnail).bottomLeading.first?.label,
            "E2 + E3"
        )
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

    func testMetadataReviewArtworkUsesTheProposedEntityThumbnailPresentation() {
        let image = AdministrativeImageCandidate(
            kind: "cover",
            url: "https://example.test/album.jpg",
            source: "musicbrainz",
            rank: 1,
            language: nil,
            width: nil,
            height: nil
        )
        let proposal = metadataProposal(kind: .audio, images: [image])

        let thumbnail = MetadataReviewThumbnailPolicy.thumbnail(for: image, in: proposal)

        XCTAssertEqual(thumbnail.kind, .audio)
        XCTAssertEqual(thumbnail.thumbnailArtworkPresentation.aspectRatio, 1)
        XCTAssertEqual(thumbnail.coverURL, image.url)
        XCTAssertEqual(
            thumbnail.id,
            MetadataReviewThumbnailPolicy.thumbnail(for: image, in: proposal).id
        )
    }

    func testPluginCandidateUsesCanonicalEntityArtworkSurface() {
        let candidate = AdministrativeEntitySearchCandidate(
            externalIDs: ["musicbrainz": "capitol"],
            title: "Capitol Records",
            posterURL: "https://example.test/capitol.png",
            candidateID: "capitol",
            source: "musicbrainz"
        )

        let thumbnail = PluginCandidateThumbnailPolicy.thumbnail(
            for: candidate,
            entityKind: EntityKind.studio.rawValue
        )

        XCTAssertEqual(thumbnail.kind, .studio)
        XCTAssertEqual(thumbnail.thumbnailArtworkPresentation.surface, .brandPlate)
        XCTAssertEqual(thumbnail.thumbnailArtworkPresentation.contentMode, .fit)
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

    private func metadataProposal(
        kind: EntityKind,
        images: [AdministrativeImageCandidate]
    ) -> AdministrativeEntityMetadataProposal {
        AdministrativeEntityMetadataProposal(
            proposalID: "proposal-1",
            provider: "musicbrainz",
            targetKind: kind,
            confidence: 1,
            matchReason: "external-id",
            patch: AdministrativeEntityMetadataPatch(
                title: "Example Album",
                description: nil,
                externalIDs: [:],
                urls: [],
                tags: [],
                studio: nil,
                credits: [],
                dates: [:],
                stats: [:],
                positions: [:],
                classification: "Album",
                rating: nil,
                flags: nil
            ),
            images: images,
            children: [],
            candidates: [],
            targetEntityID: nil,
            relationships: []
        )
    }
}
