import XCTest

@testable import PrismediaCore

final class EntityThumbnailOverlayTests: XCTestCase {
    func testWebParityOverlaysUseRatingButNotOnDiskOrganizedOrFavorite() {
        let item = thumbnail(
            rating: 4,
            isFavorite: true,
            isOrganized: true,
            hasSourceMedia: true
        )

        let policy = EntityThumbnailOverlayPolicy(item: item)

        XCTAssertEqual(policy.bottomTrailing.map(\.kind), [.rating])
        XCTAssertTrue(policy.topTrailing.isEmpty)
    }

    func testWantedBadgeReflectsTheCurrentAcquisitionState() {
        let item = thumbnail(
            isWanted: true,
            wantedStatus: AcquisitionStatus(rawValue: "downloading")
        )

        let badge = EntityThumbnailOverlayPolicy(item: item).topTrailing.first

        XCTAssertEqual(badge?.kind, .wanted)
        XCTAssertEqual(badge?.label, "Downloading")
        XCTAssertEqual(badge?.systemImage, "arrow.down.circle.fill")
        XCTAssertEqual(badge?.tone, .downloading)
    }

    func testUnknownWantedStateUsesUpdatingAndNsfwRemainsVisible() {
        let item = thumbnail(
            isNsfw: true,
            isWanted: true,
            wantedStatus: AcquisitionStatus(rawValue: "future-state")
        )

        let policy = EntityThumbnailOverlayPolicy(item: item)

        XCTAssertEqual(policy.topTrailing.map(\.kind), [.wanted, .nsfw])
        XCTAssertEqual(policy.topTrailing.first?.label, "Updating")
    }

    func testPositionUsesTheWebEpisodeAndSeasonMarkersWhenStructurallyDerivable() {
        let episode = thumbnail(kind: .video, parentKind: .videoSeason, sortOrder: 7)
        let season = thumbnail(kind: .videoSeason, parentKind: .videoSeries, sortOrder: 2)

        XCTAssertEqual(EntityThumbnailOverlayPolicy(item: episode).topLeading.first?.label, "E7")
        XCTAssertEqual(EntityThumbnailOverlayPolicy(item: season).topLeading.first?.label, "S2")
    }

    func testMovieOwnedAndStandaloneVideosDoNotInventEpisodeBadges() {
        let movieVideo = thumbnail(kind: .video, parentKind: .movie, sortOrder: 0)
        let movieVideoWithPositiveSort = thumbnail(kind: .video, parentKind: .movie, sortOrder: 3)
        let standaloneVideo = thumbnail(kind: .video, sortOrder: 4)
        let movie = thumbnail(kind: .movie, sortOrder: 1)

        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: movieVideo).topLeading.isEmpty)
        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: movieVideoWithPositiveSort).topLeading.isEmpty)
        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: standaloneVideo).topLeading.isEmpty)
        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: movie).topLeading.isEmpty)
    }

    func testZeroAndMissingOrdinalsDoNotProducePositionBadges() {
        let zeroEpisode = thumbnail(kind: .video, parentKind: .videoSeason, sortOrder: 0)
        let missingEpisode = thumbnail(kind: .video, parentKind: .videoSeries)
        let zeroSeason = thumbnail(kind: .videoSeason, parentKind: .videoSeries, sortOrder: 0)

        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: zeroEpisode).topLeading.isEmpty)
        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: missingEpisode).topLeading.isEmpty)
        XCTAssertTrue(EntityThumbnailOverlayPolicy(item: zeroSeason).topLeading.isEmpty)
    }

    private func thumbnail(
        kind: EntityKind = .video,
        parentKind: EntityKind? = nil,
        sortOrder: Int? = nil,
        rating: Int? = nil,
        isFavorite: Bool = false,
        isNsfw: Bool = false,
        isOrganized: Bool = false,
        isWanted: Bool = false,
        hasSourceMedia: Bool = false,
        wantedStatus: AcquisitionStatus? = nil
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(),
            kind: kind,
            title: "Example",
            parentKind: parentKind,
            sortOrder: sortOrder,
            rating: rating,
            isFavorite: isFavorite,
            isNsfw: isNsfw,
            isOrganized: isOrganized,
            isWanted: isWanted,
            hasSourceMedia: hasSourceMedia,
            wantedStatus: wantedStatus
        )
    }
}
