import Foundation
import XCTest

@testable import PrismediaCore

final class AudiobookQueueLoaderTests: XCTestCase {
    func testCompleteThumbnailDurationsDoNotLoadTrackDetails() async throws {
        let parts = [
            makePart(idSuffix: 2, title: "Part Two", duration: "2:00", sortOrder: 1),
            makePart(idSuffix: 1, title: "Part One", duration: "1:00", sortOrder: 0),
        ]
        let detailLoader = AudiobookQueueDetailLoaderSpy(detailsByID: [:])

        let projection = await AudiobookQueueLoader(detailLoader: detailLoader).load(
            detail: makeBook(parts: parts)
        )

        let metrics = await detailLoader.metrics()
        XCTAssertEqual(metrics.requestedIDs, [])
        XCTAssertEqual(projection?.tracks.map(\.duration), [60, 120])
    }

    func testOnlyInvalidDurationsLoadDetailsWithoutReorderingOrDiscardingFallbacks() async throws {
        let valid = makePart(idSuffix: 1, title: "Part One", duration: "1:00", sortOrder: 0)
        let missing = makePart(idSuffix: 2, title: "Part Two", duration: nil, sortOrder: 1)
        let zero = makePart(idSuffix: 3, title: "Part Three", duration: "0:00", sortOrder: 2)
        let detailLoader = AudiobookQueueDetailLoaderSpy(
            detailsByID: [missing.id: try makeTrackDetail(id: missing.id, duration: "00:02:00")]
        )

        let projection = await AudiobookQueueLoader(detailLoader: detailLoader).load(
            detail: makeBook(parts: [zero, missing, valid])
        )

        let metrics = await detailLoader.metrics()
        XCTAssertEqual(Set(metrics.requestedIDs), Set([missing.id, zero.id]))
        XCTAssertEqual(projection?.tracks.map(\.id), [valid.id, missing.id, zero.id])
        XCTAssertEqual(projection?.tracks.map(\.duration), [60, 120, 0])
    }

    func testMissingDurationHydrationNeverExceedsSixConcurrentRequests() async throws {
        let parts = (1...12).reversed().map {
            makePart(idSuffix: $0, title: "Part \($0)", duration: nil, sortOrder: $0)
        }
        let details = try Dictionary(
            uniqueKeysWithValues: parts.map {
                ($0.id, try makeTrackDetail(id: $0.id, duration: "00:01:00"))
            }
        )
        let detailLoader = AudiobookQueueDetailLoaderSpy(
            detailsByID: details,
            requestDelay: .milliseconds(30)
        )

        let projection = await AudiobookQueueLoader(detailLoader: detailLoader).load(
            detail: makeBook(parts: parts)
        )

        let metrics = await detailLoader.metrics()
        XCTAssertEqual(metrics.requestedIDs.count, parts.count)
        XCTAssertGreaterThan(metrics.maximumConcurrentRequests, 1)
        XCTAssertLessThanOrEqual(metrics.maximumConcurrentRequests, 6)
        XCTAssertEqual(projection?.tracks.map(\.id), parts.reversed().map(\.id))
    }

    private func makeBook(parts: [EntityThumbnail]) -> EntityDetail {
        EntityDetail(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            kind: .book,
            title: "The Long Voyage",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: true,
            capabilities: [],
            childrenByKind: [
                EntityGroup(kind: .audioTrack, label: "Audio Tracks", entities: parts, code: nil)
            ],
            relationships: []
        )
    }

    private func makePart(
        idSuffix: Int,
        title: String,
        duration: String?,
        sortOrder: Int
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", idSuffix))!,
            kind: .audioTrack,
            title: title,
            sortOrder: sortOrder,
            meta: duration.map { [EntityThumbnailMeta(icon: "duration", label: $0)] } ?? []
        )
    }

    private func makeTrackDetail(id: UUID, duration: String) throws -> EntityDetail {
        try PrismediaJSON.decoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {"id":"\(id.uuidString)","kind":"audio-track","title":"Track","hasSourceMedia":true,"capabilities":[{"kind":"technical","duration":"\(duration)"}],"childrenByKind":[],"relationships":[]}
                """.utf8
            )
        )
    }

}
