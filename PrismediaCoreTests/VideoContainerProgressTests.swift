import XCTest

@testable import PrismediaCore

final class VideoContainerProgressPresentationTests: XCTestCase {
    func testPartialEpisodeContributesItsPlaybackFractionToSeriesProgress() throws {
        let episodeID = UUID()
        let progress = progressCapability(
            currentEntityID: episodeID,
            index: 3,
            total: 10
        )
        let episode = VideoProgressEpisode(
            id: episodeID,
            title: "The Long Way Home",
            resumeSeconds: 300,
            durationSeconds: 600,
            isCompleted: false
        )

        let presentation = try XCTUnwrap(
            VideoContainerProgressPresentation(progress: progress, episode: episode)
        )

        XCTAssertEqual(presentation.episodeID, episodeID)
        XCTAssertEqual(presentation.status, .inProgress)
        XCTAssertEqual(presentation.percent, 35)
        XCTAssertEqual(presentation.positionLabel, "Episode 4 of 10")
        XCTAssertEqual(presentation.contextLabel, "The Long Way Home")
        XCTAssertTrue(presentation.canContinue)
    }

    func testNextUnstartedEpisodeRepresentsCompletedEpisodesBeforeIt() throws {
        let episodeID = UUID()
        let progress = progressCapability(
            currentEntityID: episodeID,
            index: 4,
            total: 10
        )
        let episode = VideoProgressEpisode(
            id: episodeID,
            title: "Next Episode",
            resumeSeconds: 0,
            durationSeconds: 600,
            isCompleted: false
        )

        let presentation = try XCTUnwrap(
            VideoContainerProgressPresentation(progress: progress, episode: episode)
        )

        XCTAssertEqual(presentation.percent, 40)
        XCTAssertEqual(presentation.status, .inProgress)
        XCTAssertTrue(presentation.canContinue)
    }

    func testCompletedContainerAlwaysPresentsOneHundredPercent() throws {
        let episodeID = UUID()
        let progress = progressCapability(
            currentEntityID: episodeID,
            index: 9,
            total: 10,
            completedAt: "2026-07-16T12:00:00Z"
        )
        let episode = VideoProgressEpisode(
            id: episodeID,
            title: "Finale",
            resumeSeconds: 0,
            durationSeconds: nil,
            isCompleted: false
        )

        let presentation = try XCTUnwrap(
            VideoContainerProgressPresentation(progress: progress, episode: episode)
        )

        XCTAssertEqual(presentation.percent, 100)
        XCTAssertEqual(presentation.status, .completed)
        XCTAssertFalse(presentation.canContinue)
    }

    func testMismatchedEpisodeDoesNotPresentContainerProgress() {
        let progress = progressCapability(
            currentEntityID: UUID(),
            index: 0,
            total: 10
        )
        let episode = VideoProgressEpisode(
            id: UUID(),
            title: "Wrong Episode",
            resumeSeconds: 0,
            durationSeconds: 600,
            isCompleted: false
        )

        XCTAssertNil(VideoContainerProgressPresentation(progress: progress, episode: episode))
    }

    private func progressCapability(
        currentEntityID: UUID,
        index: Int,
        total: Int,
        completedAt: String? = nil
    ) -> EntityProgressCapability {
        EntityProgressCapability(
            currentEntityID: currentEntityID,
            unit: .item,
            index: index,
            total: total,
            mode: nil,
            completedAt: completedAt,
            updatedAt: nil,
            workIndex: nil,
            workTotal: nil,
            location: nil
        )
    }
}

@MainActor
final class VideoContainerProgressServiceTests: XCTestCase {
    func testStartingSeasonOverTargetsItsFirstEpisodeWithAnItemReset() async throws {
        let firstEpisode = thumbnail(order: 1)
        let currentEpisode = thumbnail(order: 2)
        let season = containerDetail(
            kind: .videoSeason,
            progressEpisodeID: currentEpisode.id,
            index: 1,
            total: 2,
            children: [currentEpisode, firstEpisode]
        )
        let mutator = VideoProgressMutatorSpy(response: season)
        let service = VideoContainerProgressService(
            loader: VideoProgressLoaderStub(values: [:]),
            mutator: mutator
        )

        _ = try await service.startOver(container: season)
        let updates = await mutator.updates()
        let update = try XCTUnwrap(updates.first)

        XCTAssertEqual(update.id, season.id)
        XCTAssertEqual(update.request.currentEntityID, firstEpisode.id)
        XCTAssertEqual(update.request.unit, .item)
        XCTAssertEqual(update.request.index, 0)
        XCTAssertEqual(update.request.total, 2)
        XCTAssertTrue(update.request.reset)
        XCTAssertNil(update.request.completed)
    }

    func testCompletionToggleKeepsTheContainerCursorAndInvertsCompletion() async throws {
        let episode = thumbnail(order: 3)
        let season = containerDetail(
            kind: .videoSeason,
            progressEpisodeID: episode.id,
            index: 2,
            total: 8,
            children: [episode]
        )
        let presentation = try XCTUnwrap(
            VideoContainerProgressPresentation(
                progress: season.capability(),
                episode: VideoProgressEpisode(thumbnail: episode)
            )
        )
        let mutator = VideoProgressMutatorSpy(response: season)
        let service = VideoContainerProgressService(
            loader: VideoProgressLoaderStub(values: [:]),
            mutator: mutator
        )

        _ = try await service.toggleCompletion(
            container: season,
            presentation: presentation
        )
        let updates = await mutator.updates()
        let update = try XCTUnwrap(updates.first)

        XCTAssertEqual(update.request.currentEntityID, episode.id)
        XCTAssertEqual(update.request.index, 2)
        XCTAssertEqual(update.request.total, 8)
        XCTAssertEqual(update.request.completed, true)
        XCTAssertFalse(update.request.reset)
    }

    func testStartingSeriesOverUsesTheFirstEpisodeOfTheFirstSeason() async throws {
        let firstEpisode = thumbnail(order: 1)
        let seasonID = UUID()
        let seasonThumbnail = EntityThumbnail(
            id: seasonID,
            kind: .videoSeason,
            title: "Season 1",
            sortOrder: 1
        )
        let currentEpisodeID = UUID()
        let series = EntityDetail(
            id: UUID(),
            kind: .videoSeries,
            title: "Series",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: false,
            capabilities: [
                .progress(
                    EntityProgressCapability(
                        currentEntityID: currentEpisodeID,
                        unit: .item,
                        index: 8,
                        total: 12,
                        mode: nil,
                        completedAt: nil,
                        updatedAt: nil,
                        workIndex: nil,
                        workTotal: nil,
                        location: nil
                    )
                )
            ],
            childrenByKind: [
                EntityGroup(
                    kind: .videoSeason,
                    label: "Seasons",
                    entities: [seasonThumbnail],
                    code: nil
                )
            ],
            relationships: []
        )
        let season = EntityDetail(
            id: seasonID,
            kind: .videoSeason,
            title: "Season 1",
            parentEntityID: series.id,
            sortOrder: 1,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [
                EntityGroup(kind: .video, label: "Episodes", entities: [firstEpisode], code: nil)
            ],
            relationships: []
        )
        let mutator = VideoProgressMutatorSpy(response: series)
        let service = VideoContainerProgressService(
            loader: VideoProgressLoaderStub(values: [seasonID: season]),
            mutator: mutator
        )

        _ = try await service.startOver(container: series)
        let updates = await mutator.updates()
        let update = try XCTUnwrap(updates.first)

        XCTAssertEqual(update.request.currentEntityID, firstEpisode.id)
        XCTAssertEqual(update.request.total, 12)
        XCTAssertTrue(update.request.reset)
    }

    private func containerDetail(
        kind: EntityKind,
        progressEpisodeID: UUID,
        index: Int,
        total: Int,
        children: [EntityThumbnail]
    ) -> EntityDetail {
        EntityDetail(
            id: UUID(),
            kind: kind,
            title: "Container",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: false,
            capabilities: [
                .progress(
                    EntityProgressCapability(
                        currentEntityID: progressEpisodeID,
                        unit: .item,
                        index: index,
                        total: total,
                        mode: nil,
                        completedAt: nil,
                        updatedAt: nil,
                        workIndex: nil,
                        workTotal: nil,
                        location: nil
                    )
                )
            ],
            childrenByKind: [
                EntityGroup(kind: .video, label: "Episodes", entities: children, code: nil)
            ],
            relationships: []
        )
    }

    private func thumbnail(order: Int) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Episode \(order)",
            sortOrder: order,
            hasSourceMedia: true
        )
    }
}

private actor VideoProgressMutatorSpy: EntityProgressMutating {
    struct Update: Sendable {
        let id: UUID
        let request: EntityProgressUpdateRequest
    }

    private let response: EntityDetail
    private var recordedUpdates: [Update] = []

    init(response: EntityDetail) {
        self.response = response
    }

    func updateProgress(id: UUID, request: EntityProgressUpdateRequest) async throws -> EntityDetail {
        recordedUpdates.append(Update(id: id, request: request))
        return response
    }

    func updates() -> [Update] {
        recordedUpdates
    }
}

private actor VideoProgressLoaderStub: EntityDetailLoading {
    let values: [UUID: EntityDetail]

    init(values: [UUID: EntityDetail]) {
        self.values = values
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let detail = values[id] else { throw VideoContainerProgressTestError.missing }
        return detail
    }
}

private enum VideoContainerProgressTestError: Error {
    case missing
}
