import Foundation
import XCTest

@testable import PrismediaCore

final class AudiobookPlaybackProjectionTests: XCTestCase {
    func testBookAudioPartsStayInSourceOrderAndResumeInsideTheMatchingPart() throws {
        let parts = [
            makePart(idSuffix: 2, title: "Part Two", duration: "3:20", sortOrder: 1),
            makePart(idSuffix: 1, title: "Part One", duration: "1:40", sortOrder: 0),
        ]
        let projection = try XCTUnwrap(AudiobookPlaybackProjection(detail: makeBook(parts: parts)))

        XCTAssertEqual(projection.tracks.map(\.title), ["Part One", "Part Two"])
        XCTAssertEqual(projection.totalDuration, 300)
        XCTAssertEqual(
            projection.resumePoint(at: 145),
            AudiobookResumePoint(trackID: parts[0].id, trackOffsetSeconds: 45)
        )
    }

    func testUnknownDurationAudiobookResumesSafelyAtTheFirstPart() throws {
        let first = makePart(idSuffix: 1, title: "Part One", duration: nil, sortOrder: 0)
        let second = makePart(idSuffix: 2, title: "Part Two", duration: nil, sortOrder: 1)
        let projection = try XCTUnwrap(AudiobookPlaybackProjection(detail: makeBook(parts: [first, second])))

        XCTAssertEqual(
            projection.resumePoint(at: 90),
            AudiobookResumePoint(trackID: first.id, trackOffsetSeconds: 0)
        )
    }

    func testConcretePartTimeConvertsBackToBookAbsoluteTime() throws {
        let parts = [
            makePart(idSuffix: 1, title: "Part One", duration: "1:40", sortOrder: 0),
            makePart(idSuffix: 2, title: "Part Two", duration: "3:20", sortOrder: 1),
        ]
        let projection = try XCTUnwrap(AudiobookPlaybackProjection(detail: makeBook(parts: parts)))

        XCTAssertEqual(projection.absoluteTime(trackID: parts[1].id, trackOffsetSeconds: 25), 125)
        XCTAssertEqual(projection.absoluteTime(trackID: UUID(), trackOffsetSeconds: 25), 0)
    }

    func testExactPartBoundaryResumesAtTheNextPart() throws {
        let parts = [
            makePart(idSuffix: 1, title: "Part One", duration: "1:40", sortOrder: 0),
            makePart(idSuffix: 2, title: "Part Two", duration: "3:20", sortOrder: 1),
        ]
        let projection = try XCTUnwrap(AudiobookPlaybackProjection(detail: makeBook(parts: parts)))

        XCTAssertEqual(
            projection.resumePoint(at: 100),
            AudiobookResumePoint(trackID: parts[1].id, trackOffsetSeconds: 0)
        )
    }

    func testQueueLoaderUsesFullTechnicalDurationForTenHourPart() async throws {
        let part = makePart(idSuffix: 1, title: "Part One", duration: "10:05", sortOrder: 0)
        let technicalDetail = try JSONDecoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {
                  "id":"\(part.id.uuidString)",
                  "kind":"audio-track",
                  "title":"Part One",
                  "hasSourceMedia":true,
                  "capabilities":[{
                    "kind":"technical",
                    "duration":"10:05:00"
                  }],
                  "childrenByKind":[],
                  "relationships":[]
                }
                """.utf8
            )
        )

        let projection = await AudiobookQueueLoader(
            detailLoader: PreviewEntityDetailLoader(detail: technicalDetail)
        ).load(detail: makeBook(parts: [part]))

        XCTAssertEqual(projection?.totalDuration, 36_300)
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
}
