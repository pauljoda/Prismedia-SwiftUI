import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifyChildReviewPolicyTests: XCTestCase {
        func testCascadeShowsMatchedCurrentAndQueuedChildrenInLibraryOrder() {
            let children = [
                thumbnail(id: "10000000-0000-0000-0000-000000000001", title: "Episode 1"),
                thumbnail(id: "10000000-0000-0000-0000-000000000002", title: "Episode 2"),
                thumbnail(id: "10000000-0000-0000-0000-000000000003", title: "Episode 3"),
            ]
            let matched = proposal(
                id: "episode-1",
                title: "Matched Episode 1",
                targetEntityID: children[0].id
            )
            let root = proposal(
                id: "series",
                title: "Series",
                children: [matched]
            )

            let items = IdentifyChildReviewPolicy.items(
                children: children,
                proposal: root,
                cascadeRunning: true
            )

            XCTAssertEqual(items.map(\.entity.id), children.map(\.id))
            XCTAssertEqual(items.map(\.state), [.matched, .loading, .queued])
            XCTAssertEqual(items[0].proposal?.proposalID, "episode-1")
            XCTAssertNil(items[1].proposal)
        }

        func testCompletedCascadeMarksUnmatchedChildrenWithoutLoadingPlaceholders() {
            let children = [
                thumbnail(id: "20000000-0000-0000-0000-000000000001", title: "Episode 1"),
                thumbnail(id: "20000000-0000-0000-0000-000000000002", title: "Episode 2"),
            ]
            let root = proposal(id: "series", title: "Series")

            let items = IdentifyChildReviewPolicy.items(
                children: children,
                proposal: root,
                cascadeRunning: false
            )

            XCTAssertEqual(items.map(\.state), [.noMatch, .noMatch])
        }

        func testChildrenFiledIntoNewContainerMoveOutOfRootPlaceholders() {
            let filed = thumbnail(id: "30000000-0000-0000-0000-000000000001", title: "Chapter 1")
            let remaining = thumbnail(id: "30000000-0000-0000-0000-000000000002", title: "Chapter 2")
            let matchedChapter = proposal(
                id: "chapter-1",
                title: "Chapter 1",
                targetEntityID: filed.id
            )
            let newVolume = proposal(
                id: "volume-1",
                title: "Volume 1",
                children: [matchedChapter]
            )
            let root = proposal(
                id: "book",
                title: "Book",
                children: [newVolume]
            )

            XCTAssertEqual(
                IdentifyChildReviewPolicy.newContainers(in: root).map(\.proposalID),
                ["volume-1"]
            )
            XCTAssertEqual(
                IdentifyChildReviewPolicy.remainingChildren(
                    [filed, remaining],
                    in: root
                ).map(\.id),
                [remaining.id]
            )
        }

        private func thumbnail(id: String, title: String) -> EntityThumbnail {
            EntityThumbnail(
                id: UUID(uuidString: id)!,
                kind: .video,
                title: title,
                parentKind: .videoSeason,
                hasSourceMedia: true
            )
        }

        private func proposal(
            id: String,
            title: String,
            targetEntityID: UUID? = nil,
            children: [AdministrativeEntityMetadataProposal] = []
        ) -> AdministrativeEntityMetadataProposal {
            AdministrativeEntityMetadataProposal(
                proposalID: id,
                provider: "tmdb",
                targetKind: "video",
                confidence: 1,
                matchReason: "test",
                patch: AdministrativeEntityMetadataPatch(
                    title: title,
                    description: nil,
                    externalIDs: [:],
                    urls: [],
                    tags: [],
                    studio: nil,
                    credits: [],
                    dates: [:],
                    stats: [:],
                    positions: [:],
                    classification: nil,
                    rating: nil,
                    flags: nil
                ),
                images: [],
                children: children,
                candidates: [],
                targetEntityID: targetEntityID,
                relationships: []
            )
        }
    }
#endif
