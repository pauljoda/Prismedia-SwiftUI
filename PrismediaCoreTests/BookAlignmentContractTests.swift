import XCTest

@testable import PrismediaCore

/// Durable wire and version-gate coverage for the server-owned Book alignment (servers 3.8+).
final class BookAlignmentContractTests: XCTestCase {
    // MARK: - Decoding

    func testDecodesTheAlignmentProjectionAndItsResumeTargets() throws {
        let alignment = try PrismediaJSON.decoder().decode(
            BookAlignmentResponse.self,
            from: Data(Self.alignmentJSON.utf8)
        )

        XCTAssertEqual(alignment.modalities, [.reading, .listening])
        XCTAssertTrue(alignment.supportsReadingAndListening)
        XCTAssertEqual(alignment.readablePositionTotal, 10_000)
        XCTAssertEqual(alignment.rows.map(\.id), ["r0", "r1", "a0"])
        XCTAssertEqual(alignment.rows.map(\.matchState), [.paired, .readableOnly, .audioOnly])
        XCTAssertEqual(alignment.rows[0].provenance, .manual)
        XCTAssertEqual(alignment.rows[0].readable?.startFraction, 0)
        XCTAssertEqual(alignment.rows[0].audio?.markerID, Self.markerID)
        XCTAssertEqual(alignment.rows[2].audio?.endInferred, true)
        XCTAssertEqual(
            alignment.chapterMappings,
            [
                BookChapterAudioMapping(
                    readableChapterKey: "Text/one.xhtml",
                    audioTrackID: Self.trackID,
                    origin: .manual,
                    audioMarkerID: Self.markerID
                )
            ]
        )
        XCTAssertEqual(alignment.coverage.pairedCount, 1)
        XCTAssertEqual(alignment.coverage.totalAudioSeconds, 600)

        let resume = try XCTUnwrap(alignment.resume)
        XCTAssertEqual(resume.lastModality, .listening)
        XCTAssertEqual(resume.continueTarget?.basis, .exact)
        XCTAssertEqual(resume.continueTarget?.rowID, "a0")
        XCTAssertEqual(resume.exactListening?.offsetSeconds, 412.5)
        XCTAssertEqual(resume.listeningRowID, "a0")
        XCTAssertEqual(resume.readingRowID, "r0")
        XCTAssertNil(resume.switchToReading.aligned)
        XCTAssertEqual(resume.switchToReading.gap, .audioChapterUnpaired)
        XCTAssertEqual(
            resume.switchToReading.gapExplanation,
            "“Bonus Interview” has no matching ebook chapter."
        )
        XCTAssertEqual(resume.switchToListening.approximate, true)
        XCTAssertEqual(resume.switchToListening.basis, .interpolated)
        XCTAssertEqual(resume.switchToListening.aligned?.listening?.offsetSeconds, 115)
        XCTAssertEqual(resume.combined.basis, .exact)
    }

    func testReadingTargetsOpenTheirLocatorChapterOrPage() throws {
        let alignment = try PrismediaJSON.decoder().decode(
            BookAlignmentResponse.self,
            from: Data(Self.alignmentJSON.utf8)
        )
        let exact = try XCTUnwrap(alignment.resume?.exactReading)
        XCTAssertEqual(exact.destination(inWork: Self.bookID), .epubLocator(Self.readiumLocator))

        let webCFI = BookReadingTarget(
            positionEntityID: Self.bookID,
            unit: .cfi,
            index: 2_500,
            total: 10_000,
            location: "epubcfi(/6/4!/4/2)",
            chapterLocation: "Text/one.xhtml",
            chapterFraction: 0.5
        )
        XCTAssertEqual(
            webCFI.destination(inWork: Self.bookID),
            .epubChapter(BookReaderLocationTarget(location: "Text/one.xhtml", progression: 0.5))
        )

        let chapterID = UUID()
        let paged = BookReadingTarget(
            positionEntityID: chapterID,
            unit: .page,
            index: 3,
            total: 12,
            pageIndex: 3
        )
        XCTAssertEqual(paged.destination(inWork: Self.bookID), .chapterPage(chapterID: chapterID, pageIndex: 3))

        let pdf = BookReadingTarget(positionEntityID: Self.bookID, unit: .page, index: 4, total: 90)
        XCTAssertNil(pdf.destination(inWork: Self.bookID))
    }

    func testProgressCapabilityCarriesModalityCheckpoints() throws {
        let json = """
            {
              "currentEntityId": "\(Self.bookID)", "unit": "cfi", "index": "6000", "total": 10000,
              "mode": "paged", "completedAt": null, "updatedAt": "2026-09-24T11:00:00Z",
              "location": null, "consumedPercent": 0.6, "lastModality": "listening",
              "checkpoints": [
                {
                  "modality": "reading", "positionEntityId": "\(Self.bookID)", "unit": "cfi",
                  "index": 2300, "total": 10000, "offsetSeconds": null, "markerId": null,
                  "mode": "scrolled", "location": "epubcfi(/6/12!/4/2)",
                  "updatedAt": "2026-09-24T10:00:00.123Z", "workIndex": 2300, "workTotal": 10000
                },
                {
                  "modality": "listening", "positionEntityId": "\(Self.trackID)", "unit": "second",
                  "index": 412, "total": 600, "offsetSeconds": "412.5", "markerId": "\(Self.markerID)",
                  "mode": null, "location": null, "updatedAt": "2026-09-24T11:00:00Z"
                }
              ]
            }
            """
        let progress = try PrismediaJSON.decoder().decode(EntityProgressCapability.self, from: Data(json.utf8))

        XCTAssertEqual(progress.lastModality, .listening)
        XCTAssertEqual(progress.index, 6_000)
        XCTAssertEqual(progress.checkpoint(for: .listening)?.offsetSeconds, 412.5)
        XCTAssertEqual(progress.checkpoint(for: .listening)?.markerID, Self.markerID)
        let reading = progress.readingPosition
        XCTAssertEqual(reading.currentEntityID, Self.bookID)
        XCTAssertEqual(reading.index, 2_300)
        XCTAssertEqual(reading.mode, .scrolled)
        XCTAssertEqual(reading.location, "epubcfi(/6/12!/4/2)")
        XCTAssertEqual(reading.consumedPercent, 0.6)

        let legacy = EntityProgressCapability(
            currentEntityID: Self.bookID, unit: .cfi, index: 10, total: 10_000, mode: .paged,
            completedAt: nil, updatedAt: nil, workIndex: nil, workTotal: nil, location: nil
        )
        XCTAssertEqual(legacy.readingPosition, legacy)
    }

    // MARK: - Version gate

    func testServerVersionsGateTheAlignmentProjection() {
        XCTAssertEqual(PrismediaServerVersion("3.8.0"), PrismediaServerVersion.bookAlignment)
        XCTAssertEqual(PrismediaServerVersion("3.8.0-beta.2"), PrismediaServerVersion.bookAlignment)
        XCTAssertEqual(PrismediaServerVersion("3.9"), PrismediaServerVersion(major: 3, minor: 9))
        XCTAssertNil(PrismediaServerVersion(nil))
        XCTAssertNil(PrismediaServerVersion("dev"))
        XCTAssertTrue(PrismediaServerVersion("3.10.1")?.servesBookAlignment == true)
        XCTAssertTrue(PrismediaServerVersion("4.0.0")?.servesBookAlignment == true)
        XCTAssertFalse(PrismediaServerVersion("3.7.12")?.servesBookAlignment == true)
    }

    func testQualifyingServerLoadsTheProjectionAndReadsHealthOnce() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"status":"ok","runtime":"dotnet","version":"3.8.0"}"#),
            .json(Self.alignmentJSON),
            .json(Self.alignmentJSON),
        ])
        let client = Self.client(loader: loader)

        let first = try await BookAlignmentLoader(service: client).load(bookID: Self.bookID)
        let second = try await BookAlignmentLoader(service: client.authenticated(with: "next")).load(
            bookID: Self.bookID
        )

        XCTAssertEqual(first.contract, .serverAlignment)
        XCTAssertEqual(second.contract, .serverAlignment)
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            ["/api/health", Self.alignmentPath, Self.alignmentPath]
        )
    }

    func testOlderServersUseTheLegacyChapterMap() async throws {
        for health in [#"{"status":"ok","runtime":"dotnet"}"#, #"{"status":"ok","version":"3.7.4"}"#] {
            let loader = MockHTTPDataLoader(responses: [.json(health), .json(#"{"mappings":[]}"#)])

            let snapshot = try await BookAlignmentLoader(service: Self.client(loader: loader)).load(
                bookID: Self.bookID
            )

            XCTAssertEqual(snapshot, .legacy(BookChapterMappingsResponse(mappings: [])))
            XCTAssertEqual(loader.requests.map { $0.url?.path }, ["/api/health", Self.mappingsPath])
        }
    }

    func testQualifyingServerWithoutTheRouteFallsBackToTheLegacyChapterMap() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"status":"ok","version":"3.8.0"}"#),
            .json("", statusCode: 404),
            .json(#"{"mappings":[]}"#),
        ])

        let snapshot = try await BookAlignmentLoader(service: Self.client(loader: loader)).load(bookID: Self.bookID)

        XCTAssertEqual(snapshot.contract, .legacyCursor)
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            ["/api/health", Self.alignmentPath, Self.mappingsPath]
        )
    }

    func testMissingBookOnAQualifyingServerKeepsTheServerContract() async {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"status":"ok","version":"3.8.0"}"#),
            .json(#"{"code":"entity_not_found","message":"Not found"}"#, statusCode: 404),
        ])

        do {
            _ = try await BookAlignmentLoader(service: Self.client(loader: loader)).load(bookID: Self.bookID)
            XCTFail("A hidden Book must not fall back to the legacy chapter map.")
        } catch let error as BookAlignmentLoadError {
            XCTAssertEqual(error.contract, .serverAlignment)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
        XCTAssertEqual(loader.requests.count, 2)
    }

    func testSavingOnAQualifyingServerDecodesTheRefreshedAlignment() async throws {
        let loader = MockHTTPDataLoader(responses: [.json(Self.alignmentJSON)])

        let snapshot = try await BookAlignmentLoader(service: Self.client(loader: loader)).save(
            bookID: Self.bookID,
            mappings: [BookChapterAudioMapping(readableChapterKey: "Text/one.xhtml", audioTrackID: Self.trackID)],
            contract: .serverAlignment
        )

        guard case .server(let alignment) = snapshot else {
            return XCTFail("Expected the server alignment.")
        }
        XCTAssertEqual(alignment.rows.count, 3)
        XCTAssertEqual(loader.requests.first?.url?.path, Self.mappingsPath)
        XCTAssertEqual(loader.requests.first?.httpMethod, "PUT")
    }

    // MARK: - Progress reports

    func testReadingReportsNameTheirModalityInTheServerPositionTotal() throws {
        let request = DocumentReaderProgressMapper.epubRequest(
            bookID: Self.bookID,
            progression: 0.25,
            mode: .paged,
            location: Self.readiumLocator,
            closing: false,
            format: BookReadingReportFormat(positionTotal: 20_000, modality: .reading)
        )

        let body = try Self.encodedBody(request)
        XCTAssertEqual(body["modality"] as? String, "reading")
        XCTAssertEqual(body["currentEntityId"] as? String, Self.bookID.uuidString)
        XCTAssertEqual(body["unit"] as? String, "cfi")
        XCTAssertEqual(body["index"] as? Int, 5_000)
        XCTAssertEqual(body["total"] as? Int, 20_000)
        XCTAssertEqual(body["mode"] as? String, "paged")
        XCTAssertEqual(body["location"] as? String, Self.readiumLocator)
        XCTAssertNil(body["listening"])
        XCTAssertEqual(BookReadingReportFormat(kind: .book, alignment: nil).modality, .reading)
        XCTAssertNil(BookReadingReportFormat(kind: .comicInstallment, alignment: nil).modality)
    }

    func testListeningReportsCarryOnlyTheExactTrackPosition() throws {
        let request = EntityProgressUpdateRequest.listening(
            BookListeningPositionRequest(trackEntityID: Self.trackID, markerID: nil, offsetSeconds: 412.5),
            completed: nil,
            activitySeconds: 10
        )

        let body = try Self.encodedBody(request)
        XCTAssertEqual(body["modality"] as? String, "listening")
        let listening = try XCTUnwrap(body["listening"] as? [String: Any])
        XCTAssertEqual(listening["trackEntityId"] as? String, Self.trackID.uuidString)
        XCTAssertTrue(listening["markerId"] is NSNull)
        XCTAssertEqual(listening["offsetSeconds"] as? Double, 412.5)
        XCTAssertTrue(body["completed"] is NSNull)
        XCTAssertEqual(body["reset"] as? Bool, false)
        XCTAssertEqual(body["activitySeconds"] as? Double, 10)
        for cursorKey in ["currentEntityId", "unit", "index", "total", "mode", "location", "activityKind"] {
            XCTAssertNil(body[cursorKey], "A listening report must not name a cursor field: \(cursorKey)")
        }
    }

    // MARK: - Fixtures

    private static let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let trackID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private static let markerID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    private static let readiumLocator = #"{"href":"Text/one.xhtml","locations":{"progression":0.4}}"#
    private static let alignmentPath = "/api/books/\(bookID.uuidString.lowercased())/alignment"
    private static let mappingsPath = "/api/books/\(bookID.uuidString.lowercased())/chapter-mappings"

    private static func encodedBody(_ request: EntityProgressUpdateRequest) throws -> [String: Any] {
        let data = try PrismediaJSON.encoder().encode(request)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private static func client(loader: MockHTTPDataLoader) -> PrismediaAPIClient {
        PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )
    }

    private static let alignmentJSON: String = {
        let locator = #""{\"href\":\"Text/one.xhtml\",\"locations\":{\"progression\":0.4}}""#
        return """
            {
              "modalities": ["reading", "listening"],
              "readablePositionTotal": 10000,
              "rows": [
                {
                  "rowId": "r0", "order": 0, "matchState": "paired", "provenance": "manual",
                  "readable": {
                    "chapterKey": "Text/one.xhtml", "title": "One", "depth": 0,
                    "location": "Text/one.xhtml", "chapterEntityId": null,
                    "startFraction": 0, "endFraction": 0.5, "pageCount": null
                  },
                  "audio": {
                    "trackEntityId": "\(trackID)", "markerId": "\(markerID)", "title": "Chapter One",
                    "startSeconds": 0, "endSeconds": 300, "endInferred": false
                  }
                },
                {
                  "rowId": "r1", "order": 1, "matchState": "readable_only", "provenance": null,
                  "readable": {
                    "chapterKey": "Text/two.xhtml", "title": "Two", "depth": 0,
                    "location": "Text/two.xhtml", "chapterEntityId": null,
                    "startFraction": "0.5", "endFraction": "1", "pageCount": null
                  },
                  "audio": null
                },
                {
                  "rowId": "a0", "order": 2, "matchState": "audio_only", "provenance": null,
                  "readable": null,
                  "audio": {
                    "trackEntityId": "\(trackID)", "markerId": null, "title": "Bonus Interview",
                    "startSeconds": 300, "endSeconds": 600, "endInferred": true
                  }
                }
              ],
              "coverage": {
                "readableCount": 2, "audioWindowCount": 2, "pairedCount": 1, "manualCount": 1,
                "automaticCount": 0, "readableOnlyCount": 1, "audioOnlyCount": 1,
                "pairedReadableFraction": 0.5, "pairedAudioSeconds": 300, "totalAudioSeconds": 600
              },
              "resume": {
                "lastModality": "listening",
                "completedAt": null,
                "continue": {
                  "rowId": "a0", "reading": null,
                  "listening": { "trackEntityId": "\(trackID)", "markerId": null, "offsetSeconds": 412.5 },
                  "approximate": false, "basis": "exact", "gap": null, "gapChapterTitle": null
                },
                "exactReading": {
                  "positionEntityId": "\(bookID)", "unit": "cfi", "index": 2000, "total": 10000,
                  "location": \(locator), "chapterKey": "Text/one.xhtml",
                  "chapterLocation": "Text/one.xhtml", "chapterFraction": 0.4, "pageIndex": null,
                  "mode": "paged"
                },
                "exactListening": { "trackEntityId": "\(trackID)", "markerId": null, "offsetSeconds": 412.5 },
                "switchToReading": {
                  "rowId": "a0", "reading": null, "listening": null, "approximate": false,
                  "basis": "exact", "gap": "audio_chapter_unpaired", "gapChapterTitle": "Bonus Interview"
                },
                "switchToListening": {
                  "rowId": "r0", "reading": null,
                  "listening": { "trackEntityId": "\(trackID)", "markerId": "\(markerID)", "offsetSeconds": 115 },
                  "approximate": true, "basis": "interpolated", "gap": null, "gapChapterTitle": null
                },
                "combined": {
                  "rowId": "a0", "reading": null,
                  "listening": { "trackEntityId": "\(trackID)", "markerId": null, "offsetSeconds": 412.5 },
                  "approximate": false, "basis": "exact", "gap": "audio_chapter_unpaired",
                  "gapChapterTitle": "Bonus Interview"
                }
              }
            }
            """
    }()
}
