import XCTest

@testable import PrismediaCore

final class EntityChildAcquisitionActivityPolicyTests: XCTestCase {
    private let parentID = UUID(uuidString: "10000000-0000-0000-0000-000000000000")!
    private let referenceDate = Date(timeIntervalSince1970: 1_783_792_800)

    func testEligibleChildrenIncludeEveryDirectRequestableKindOnly() {
        let requestableKinds: [EntityKind] = [
            .audioLibrary,
            .audioTrack,
            .book,
            .musicArtist,
            .bookAuthor,
            .movie,
            .video,
            .videoSeries,
            .videoSeason,
        ]
        let directChildren = requestableKinds.enumerated().map { index, kind in
            entity(
                id: String(format: "20000000-0000-0000-0000-%012d", index + 1),
                kind: kind,
                parentID: parentID
            )
        }
        let directImage = entity(
            id: "20000000-0000-0000-0000-000000000010",
            kind: .image,
            parentID: parentID
        )
        let nestedEpisode = entity(
            id: "20000000-0000-0000-0000-000000000011",
            kind: .video,
            parentID: directChildren.last!.id
        )
        let groups = [
            EntityGroup(
                kind: .video,
                label: "Children",
                entities: directChildren + [directImage, nestedEpisode],
                code: "children"
            ),
        ]

        let children = EntityChildAcquisitionActivityPolicy.eligibleChildren(
            parentID: parentID,
            groups: groups
        )

        XCTAssertEqual(children.map(\.id), directChildren.map(\.id))
    }

    func testRowsPutAttentionBeforeActiveAndTerminalWhilePreservingGraphOrderWithinEachTier() {
        let imported = item(id: 1, status: "imported")
        let downloading = item(id: 2, status: "downloading")
        let failed = item(id: 3, status: "failed")
        let searching = item(id: 4, status: "searching")
        let actionRequired = item(id: 5, status: "manual-import-required")
        let cancelled = item(id: 6, status: "cancelled")

        let ordered = EntityChildAcquisitionActivityPolicy.orderedItems([
            imported,
            downloading,
            failed,
            searching,
            actionRequired,
            cancelled,
        ])

        XCTAssertEqual(
            ordered.map(\.id),
            [failed.id, actionRequired.id, downloading.id, searching.id, imported.id, cancelled.id]
        )
    }

    func testPreparingMetadataIsActivityWithoutAnAcquisition() {
        let child = entity(id: "30000000-0000-0000-0000-000000000001", kind: .video)
        let state = monitorState(
            entityID: child.id,
            status: nil,
            monitorStatus: .active,
            canRequest: true
        )

        let item = EntityChildAcquisitionActivityItem(entity: child, state: state)

        XCTAssertTrue(item.isPreparingMetadata)
        XCTAssertTrue(item.hasActivity)
        XCTAssertTrue(EntityChildAcquisitionActivityPolicy.shouldAutoExpand([item]))
        XCTAssertTrue(EntityChildAcquisitionActivityPolicy.shouldPoll([item]))
    }

    func testUnknownStatusPollsAndExpandsWhileQuietTerminalRowsDoNeither() {
        let unknown = item(id: 1, status: "future-status")
        let imported = item(id: 2, status: "imported")
        let cancelled = item(id: 3, status: "cancelled")

        XCTAssertTrue(EntityChildAcquisitionActivityPolicy.shouldPoll([unknown]))
        XCTAssertTrue(EntityChildAcquisitionActivityPolicy.shouldAutoExpand([unknown]))
        XCTAssertFalse(EntityChildAcquisitionActivityPolicy.shouldPoll([imported, cancelled]))
        XCTAssertFalse(EntityChildAcquisitionActivityPolicy.shouldAutoExpand([imported, cancelled]))
    }

    func testChooseReleaseRequiresAttentionAndDownloadedContinuesPolling() {
        let awaitingSelection = item(id: 1, status: "awaiting-selection")
        let downloaded = item(id: 2, status: "downloaded")

        XCTAssertTrue(
            EntityChildAcquisitionActivityPolicy.isAttentionRequired(awaitingSelection)
        )
        XCTAssertTrue(
            EntityChildAcquisitionActivityPolicy.shouldAutoExpand([awaitingSelection])
        )
        XCTAssertTrue(EntityChildAcquisitionActivityPolicy.shouldPoll([downloaded]))
    }

    private func item(id: Int, status: String) -> EntityChildAcquisitionActivityItem {
        let entityID = UUID(
            uuidString: String(format: "40000000-0000-0000-0000-%012d", id)
        )!
        return EntityChildAcquisitionActivityItem(
            entity: entity(
                id: entityID.uuidString,
                kind: .video,
                parentID: parentID
            ),
            state: monitorState(
                entityID: entityID,
                status: status,
                monitorStatus: nil,
                canRequest: true
            )
        )
    }

    private func entity(
        id: String,
        kind: EntityKind,
        parentID: UUID? = nil
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: id)!,
            kind: kind,
            title: "Child \(id.suffix(2))",
            parentEntityID: parentID,
            isWanted: true
        )
    }

    private func monitorState(
        entityID: UUID,
        status: String?,
        monitorStatus: EntityMonitorStatus?,
        canRequest: Bool
    ) -> EntityMonitorState {
        EntityMonitorState(
            entityID: entityID,
            canMonitor: true,
            canRequest: canRequest,
            trackableProviders: ["TMDB"],
            discoversChildren: false,
            canSearchMissingChildren: false,
            missingChildEntityKind: nil,
            monitor: monitorStatus.map {
                EntityMonitor(
                    id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
                    kind: .video,
                    acquisitionID: nil,
                    status: $0,
                    title: "Child",
                    author: nil,
                    acquisitionStatus: status.map(AcquisitionStatus.init(rawValue:)),
                    createdAt: referenceDate,
                    updatedAt: referenceDate,
                    entityID: entityID,
                    preset: "all"
                )
            },
            latestAcquisition: status.map {
                EntityAcquisitionSummary(
                    id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
                    status: AcquisitionStatus(rawValue: $0),
                    statusMessage: $0 == "failed" ? "Release could not be imported." : nil,
                    title: "Child",
                    progress: $0 == "downloading" ? 0.42 : nil,
                    createdAt: referenceDate,
                    updatedAt: referenceDate,
                    kind: .video,
                    entityID: entityID
                )
            }
        )
    }
}
