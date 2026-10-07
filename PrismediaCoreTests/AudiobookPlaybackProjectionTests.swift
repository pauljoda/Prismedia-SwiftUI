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
        XCTAssertTrue(projection.preservesQueueOrder)
        XCTAssertTrue(projection.supportsPlaybackRate)
        XCTAssertEqual(projection.totalDuration, 300)
        XCTAssertEqual(
            projection.resumePoint(at: 145),
            AudiobookResumePoint(trackID: parts[0].id, trackOffsetSeconds: 45)
        )
    }

    func testAlignmentTitlesChaptersAndSingleWindowPartsWithListeningTitles() {
        let chaptered = MusicTrack(id: UUID(), title: "Part One", duration: 120)
        let whole = MusicTrack(id: UUID(), title: "006", duration: 90)
        let untouched = MusicTrack(id: UUID(), title: "Part Three", duration: 30)
        let olderServer = MusicTrack(id: UUID(), title: "007", duration: 60)
        let jon = UUID()
        let alignment = BookAlignmentResponse(
            modalities: [.listening],
            readablePositionTotal: 10_000,
            rows: [
                audioRow(chaptered.id, markerID: jon, title: "004", start: 0, listeningTitle: "Jon"),
                audioRow(chaptered.id, markerID: UUID(), title: "005", start: 60, listeningTitle: nil),
                audioRow(whole.id, markerID: nil, title: "006", start: 0, listeningTitle: "Moira"),
                // A server that predates listening titles still sends the mapped ebook chapter.
                audioRow(
                    olderServer.id,
                    markerID: nil,
                    title: "007",
                    start: 0,
                    listeningTitle: nil,
                    readableTitle: "Bran"
                ),
            ]
        )
        let projection = AudiobookPlaybackProjection(
            bookID: UUID(),
            title: "Book",
            tracks: [chaptered, whole, untouched, olderServer]
        ).withChapters(from: alignment)

        XCTAssertEqual(projection.tracks.map(\.title), ["Part One", "Moira", "Part Three", "Bran"])
        XCTAssertEqual(projection.tracks[0].chapters.map(\.title), ["Jon", "005"])
        XCTAssertEqual(projection.tracks[0].chapters.first?.markerID, jon)
        XCTAssertEqual(projection.tracks[1].chapters, [])
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

    func testSourceLessAggregateTrackIsNotIncludedInAudiobookPlayback() throws {
        let aggregate = makePart(
            idSuffix: 99,
            title: "The Long Voyage",
            duration: "47:32:34",
            sortOrder: 0,
            hasSourceMedia: false
        )
        let playable = makePart(
            idSuffix: 1,
            title: "Part One",
            duration: "1:40",
            sortOrder: 1
        )

        let projection = try XCTUnwrap(
            AudiobookPlaybackProjection(detail: makeBook(parts: [aggregate, playable]))
        )

        XCTAssertEqual(projection.tracks.map(\.id), [playable.id])
        XCTAssertEqual(projection.totalDuration, 100)
    }

    private func makeBook(parts: [EntityThumbnail]) -> EntityDetail {
        EntityDetail(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            kind: .book,
            title: "The Long Voyage",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: true,
            capabilities: [
                .playableAudio(
                    EntityPlayableAudioCapability(
                        itemKind: .audioTrack,
                        preservesQueueOrder: true,
                        supportsPlaybackRate: true
                    ))
            ],
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
        sortOrder: Int,
        hasSourceMedia: Bool = true
    ) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", idSuffix))!,
            kind: .audioTrack,
            title: title,
            sortOrder: sortOrder,
            meta: duration.map { [EntityThumbnailMeta(icon: "duration", label: $0)] } ?? [],
            hasSourceMedia: hasSourceMedia
        )
    }

    private func audioRow(
        _ trackID: UUID,
        markerID: UUID?,
        title: String,
        start: Double,
        listeningTitle: String?,
        readableTitle: String? = nil
    ) -> BookAlignmentRow {
        BookAlignmentRow(
            id: "\(trackID):\(markerID?.uuidString ?? "whole")",
            order: 0,
            matchState: readableTitle == nil ? .audioOnly : .paired,
            readable: readableTitle.map { BookReadableChapterWindow(chapterKey: "Text/\($0).xhtml", title: $0) },
            audio: BookAudioChapterWindow(
                trackEntityID: trackID,
                markerID: markerID,
                title: title,
                startSeconds: start
            ),
            listeningTitle: listeningTitle
        )
    }
}
