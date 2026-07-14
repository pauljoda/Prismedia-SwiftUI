import XCTest

@testable import PrismediaCore

final class EntityDetailPresentationTests: XCTestCase {
    func testMovieSectionsMatchTheLiveDetailOrder() throws {
        let detail = try makeDetail(
            kind: "movie",
            hasSourceMedia: true,
            capabilities: """
                [
                  { "kind": "description", "value": "A story." },
                  { "kind": "flags", "isFavorite": false, "isOrganized": true, "isWanted": false },
                  { "kind": "markers", "items": [{ "id": "intro", "title": "Intro", "seconds": 12 }] },
                  { "kind": "subtitles", "items": [{ "id": "en", "language": "en", "format": "vtt", "source": "embedded", "storagePath": "subtitles/en.vtt", "sourceFormat": "vtt", "isDefault": true }] },
                  { "kind": "technical", "duration": "1:21:07", "width": 3840, "height": 2160, "codec": "hevc", "container": "mkv" }
                ]
                """
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertEqual(presentation.sections.map(\.id), [.details, .metadata, .markers, .transcript, .acquisition])
        XCTAssertEqual(presentation.sections.first { $0.id == .markers }?.count, 1)
        XCTAssertEqual(presentation.sections.first { $0.id == .transcript }?.count, 1)
        XCTAssertEqual(presentation.actions.map(\.id), [.favorite, .organized, .edit, .identify])
    }

    func testSourceMediaOffersPWAHeaderActions() throws {
        let detail = try makeDetail(
            kind: "book",
            hasSourceMedia: true,
            capabilities: """
                [
                  { "kind": "flags", "isFavorite": true, "isOrganized": false, "isWanted": false },
                  { "kind": "progress", "currentEntityId": "22222222-2222-2222-2222-222222222222", "unit": "page", "index": 10, "total": 100 }
                ]
                """,
            format: "image-archive"
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertEqual(presentation.actions.map(\.id), [.favorite, .organized, .edit, .identify, .resume])
        XCTAssertEqual(presentation.actions.last?.title, "Resume")
        XCTAssertEqual(presentation.primaryActions.map(\.id), [.resume])
        XCTAssertEqual(presentation.modificationActions.map(\.id), [.favorite, .organized, .edit, .identify])
    }

    func testEmptyProgressCapabilityDoesNotInventAResumeTarget() throws {
        let detail = try makeDetail(
            kind: "book",
            hasSourceMedia: true,
            capabilities: #"[{ "kind": "progress", "unit": "page", "index": 0, "total": 0 }]"#,
            format: "image-archive"
        )

        XCTAssertEqual(EntityDetailPresentation(detail: detail).primaryActions.map(\.id), [.read])
    }

    func testBookWithoutProgressKeepsReadSeparateFromModificationActions() throws {
        let detail = try makeDetail(
            kind: "book",
            hasSourceMedia: true,
            capabilities: #"[{ "kind": "flags", "isFavorite": false, "isOrganized": false, "isWanted": false }]"#,
            format: "image-archive"
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertEqual(presentation.primaryActions.map(\.id), [.read])
        XCTAssertEqual(presentation.modificationActions.map(\.id), [.favorite, .organized, .edit, .identify])
    }

    func testAudioOnlyBookDoesNotOfferADeadReaderAction() throws {
        let detail = try makeDetail(
            kind: "book",
            hasSourceMedia: true,
            capabilities: "[]",
            format: "audio"
        )

        XCTAssertTrue(EntityDetailPresentation(detail: detail).primaryActions.isEmpty)
    }

    func testBookWithoutSpecializedFormatDoesNotInventAComicReaderAction() throws {
        let detail = try makeDetail(
            kind: "book",
            hasSourceMedia: true,
            capabilities: #"[{ "kind": "progress", "unit": "cfi", "index": 305, "total": 10000 }]"#
        )

        XCTAssertTrue(EntityDetailPresentation(detail: detail).primaryActions.isEmpty)
    }

    func testPersonUsesAStandaloneDetailsSurfaceWithoutTabs() throws {
        let detail = try makeDetail(
            kind: "person",
            hasSourceMedia: false,
            capabilities: #"[{ "kind": "description", "value": "Performer" }]"#
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertTrue(presentation.sections.isEmpty)
        XCTAssertEqual(presentation.actions.map(\.id), [.edit])
    }

    func testSeriesDoesNotInventAPlaybackActionForDescendantMedia() throws {
        let detail = try makeDetail(
            kind: "video-series",
            hasSourceMedia: true,
            capabilities: #"[{ "kind": "flags", "isFavorite": false, "isOrganized": true, "isWanted": false }]"#
        )

        XCTAssertEqual(
            EntityDetailPresentation(detail: detail).actions.map(\.id),
            [.favorite, .organized, .edit, .identify]
        )
        XCTAssertTrue(EntityDetailPresentation(detail: detail).primaryActions.isEmpty)
    }

    func testGenericAudioDetailDoesNotExposeAnUnsupportedPlayAction() throws {
        let detail = try makeDetail(
            kind: "audio",
            hasSourceMedia: true,
            capabilities: #"[{ "kind": "flags", "isFavorite": false, "isOrganized": true, "isWanted": false }]"#
        )

        XCTAssertFalse(EntityDetailPresentation(detail: detail).actions.contains { $0.id == .play })
    }

    func testMetadataPreservesOnlySafeExternalHTTPLinks() throws {
        let detail = try makeDetail(
            kind: "gallery",
            hasSourceMedia: true,
            capabilities: """
                [{
                  "kind": "links",
                  "urls": [
                    { "label": "Official", "value": "https://example.com/work" },
                    { "label": "Unsafe", "value": "javascript:alert(1)" }
                  ],
                  "externalIds": []
                }]
                """
        )

        let links = EntityDetailPresentation(detail: detail).metadata.filter { $0.systemImage == "link" }

        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0].url, URL(string: "https://example.com/work"))
        XCTAssertNil(links[1].url)
    }

    func testRatingCapabilityRemainsVisibleWhenEntityIsUnrated() throws {
        let detail = try makeDetail(
            kind: "movie",
            hasSourceMedia: true,
            capabilities: #"[{ "kind": "rating", "value": null }]"#
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertTrue(presentation.hasRatingCapability)
        XCTAssertNil(presentation.rating)
    }

    func testOrganizedStateIsRepresentedByActionInsteadOfDuplicateChip() throws {
        let detail = try makeDetail(
            kind: "video-series",
            hasSourceMedia: true,
            capabilities:
                #"[{ "kind": "flags", "isFavorite": false, "isNsfw": false, "isOrganized": true, "isWanted": false }]"#
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertEqual(presentation.actions.filter { $0.id == .organized }.count, 1)
        XCTAssertFalse(presentation.flagItems.contains { $0.title == "Organized" })
    }

    func testHeroUsesOnlyAnExplicitBackdropAsset() throws {
        let detail = try makeDetail(
            kind: "movie",
            hasSourceMedia: true,
            capabilities: """
                [{
                  "kind": "images",
                  "supportedKinds": ["poster", "backdrop", "logo"],
                  "items": [
                    { "kind": "logo", "path": "/assets/logo.png" },
                    { "kind": "poster", "path": "/assets/poster.jpg" },
                    { "kind": "backdrop", "path": "/assets/backdrop.jpg" }
                  ],
                  "thumbnailUrl": "/assets/thumb.jpg",
                  "thumbnail2xUrl": "/assets/thumb@2x.jpg",
                  "coverUrl": "/assets/cover.jpg"
                }]
                """
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertEqual(presentation.heroPath, "/assets/backdrop.jpg")
        XCTAssertEqual(presentation.posterPath, "/assets/poster.jpg")
    }

    func testPosterNeverSubstitutesForAMissingHero() throws {
        let detail = try makeDetail(
            kind: "movie",
            hasSourceMedia: true,
            capabilities: """
                [{
                  "kind": "images",
                  "supportedKinds": ["poster", "logo"],
                  "items": [
                    { "kind": "backdrop", "path": "  " },
                    { "kind": "logo", "path": "/assets/logo.png" },
                    { "kind": "poster", "path": "/assets/poster.jpg" }
                  ],
                  "thumbnailUrl": "/assets/thumb.jpg",
                  "thumbnail2xUrl": null,
                  "coverUrl": null
                }]
                """
        )

        let presentation = EntityDetailPresentation(detail: detail)

        XCTAssertNil(presentation.heroPath)
        XCTAssertEqual(presentation.posterPath, "/assets/poster.jpg")
    }

    private func makeDetail(
        kind: String,
        hasSourceMedia: Bool,
        capabilities: String,
        format: String? = nil
    ) throws -> EntityDetail {
        let formatField = format.map { #""format": "\#($0)","# } ?? ""
        let json = """
            {
              "id": "99999999-9999-9999-9999-999999999999",
              "kind": "\(kind)",
              "title": "Reference Entity",
              "parentEntityId": null,
              "sortOrder": null,
              \(formatField)
              "hasSourceMedia": \(hasSourceMedia),
              "capabilities": \(capabilities),
              "childrenByKind": [],
              "relationships": []
            }
            """
        return try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
    }
}
