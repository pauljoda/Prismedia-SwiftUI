import XCTest

@testable import PrismediaCore

final class MusicPresentationTests: XCTestCase {
    func testClockTimeFormatsMinutesAndSeconds() {
        XCTAssertEqual(MusicPresentation.clockTime(0), "0:00")
        XCTAssertEqual(MusicPresentation.clockTime(65), "1:05")
        XCTAssertEqual(MusicPresentation.clockTime(3_661), "1:01:01")
    }

    func testArtistFallsBackToUnknownArtist() {
        XCTAssertEqual(MusicPresentation.artist(nil), "Unknown Artist")
        XCTAssertEqual(MusicPresentation.artist("  "), "Unknown Artist")
        XCTAssertEqual(MusicPresentation.artist("AmaLee"), "AmaLee")
    }

    func testLibrarySectionsGroupTitleSortAlphabetically() {
        let items = [
            EntityThumbnail(id: UUID(), kind: .musicArtist, title: "The Beatles"),
            EntityThumbnail(id: UUID(), kind: .musicArtist, title: "AmaLee"),
            EntityThumbnail(id: UUID(), kind: .musicArtist, title: "1nonly"),
        ]

        let sections = MusicLibrarySection.sections(
            for: items,
            sort: .title,
            sortDescending: false
        )

        XCTAssertEqual(sections.map(\.title), ["#", "A", "T"])
        XCTAssertEqual(sections[1].items.map(\.title), ["AmaLee"])
    }

    func testLibrarySectionsMirrorDescendingTitleSort() {
        let items = [
            EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Aardvark"),
            EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Zulu"),
            EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Azure"),
            EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "1nonly"),
        ]

        let sections = MusicLibrarySection.sections(
            for: items,
            sort: .title,
            sortDescending: true
        )

        XCTAssertEqual(sections.map(\.title), ["Z", "A", "#"])
        XCTAssertEqual(sections[1].items.map(\.title), ["Azure", "Aardvark"])
    }

    func testLibrarySectionsPreserveServerOrderForNonTitleSorts() throws {
        let items = [
            EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Zulu"),
            EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Alpha"),
            EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Middle"),
        ]

        for sort in [EntityGridSort.added, .rating, .random] {
            for sortDescending in [false, true] {
                let sections = MusicLibrarySection.sections(
                    for: items,
                    sort: sort,
                    sortDescending: sortDescending
                )
                let section = try XCTUnwrap(sections.first)

                XCTAssertEqual(sections.count, 1)
                XCTAssertEqual(section.title, "")
                XCTAssertEqual(section.items.map(\.id), items.map(\.id))
            }
        }
    }

    func testLibrarySortsUseConventionalInitialDirections() {
        XCTAssertFalse(EntityGridSort.title.defaultDescending)
        XCTAssertTrue(EntityGridSort.added.defaultDescending)
        XCTAssertTrue(EntityGridSort.rating.defaultDescending)
        XCTAssertFalse(EntityGridSort.random.defaultDescending)
    }

    func testAlbumArtistReadsArtistMetadata() {
        let album = EntityThumbnail(
            id: UUID(),
            kind: .audioLibrary,
            title: "1",
            meta: [EntityThumbnailMeta(icon: "artist", label: "The Beatles")]
        )

        XCTAssertEqual(MusicPresentation.albumArtist(album), "The Beatles")
    }

    func testAlbumArtistUsesResolvedStructuralParentBeforeMetadataFallback() {
        let artistID = UUID()
        let album = EntityThumbnail(
            id: UUID(),
            kind: .audioLibrary,
            title: "Smoke + Mirrors",
            parentEntityID: artistID,
            meta: [EntityThumbnailMeta(icon: "artist", label: "Old Name")]
        )

        XCTAssertEqual(
            MusicPresentation.albumArtist(album, artistNamesByID: [artistID: "Imagine Dragons"]),
            "Imagine Dragons"
        )
    }

    func testTrackSectionsPreserveDiscLabelsAndResetVisibleNumbering() throws {
        let json = """
            {"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","kind":"audio-library","title":"Smoke + Mirrors","hasSourceMedia":true,"capabilities":[],"relationships":[],
            "childrenByKind":[{"kind":"audio-track","label":"Tracks","entities":[
              {"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1","kind":"audio-track","title":"Shots","sortOrder":0,"meta":[{"icon":"disc","label":"12 Vinyl 01"},{"icon":"duration","label":"03:52"}]},
              {"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2","kind":"audio-track","title":"Summer","sortOrder":10,"meta":[{"icon":"disc","label":"12 Vinyl 02"},{"icon":"duration","label":"03:38"}]}
            ]}]}
            """
        let detail = try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))

        let sections = MusicTrackSection.sections(for: MusicEntityProjection.tracks(in: detail))

        XCTAssertEqual(sections.map(\.title), ["12 Vinyl 01", "12 Vinyl 02"])
        XCTAssertEqual(sections.flatMap(\.tracks).map(\.discNumber), [1, 2])
        XCTAssertTrue(sections.flatMap(\.tracks).allSatisfy { $0.trackNumber == nil })
    }

    func testAlbumFactsUseRealReleaseClassificationDurationAndDistinctDiscLabels() throws {
        let json = """
            {"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","kind":"audio-library","title":"Smoke + Mirrors","hasSourceMedia":true,
            "capabilities":[{"kind":"dates","items":[{"code":"released","value":"2015-02-17"}]},{"kind":"classification","value":"Album","system":"plugin"}],
            "relationships":[{"kind":"studio","label":"Studios","entities":[{"id":"dddddddd-dddd-dddd-dddd-dddddddddddd","kind":"studio","title":"KIDinaKORNER"}]}],"childrenByKind":[]}
            """
        let detail = try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
        let tracks = [
            MusicTrack(id: UUID(), title: "One", duration: 120, discNumber: 1, discTitle: "12 Vinyl 01"),
            MusicTrack(id: UUID(), title: "Two", duration: 180, discNumber: 2, discTitle: "12 Vinyl 02"),
        ]

        let facts = MusicPresentation.albumFacts(detail: detail, tracks: tracks)

        XCTAssertEqual(facts.primary, "2015 • Album • KIDinaKORNER")
        XCTAssertEqual(facts.secondary, "2 songs • 2 discs • 5:00")
    }

    func testTrackProjectionAcceptsAudioRelationshipGroups() throws {
        let json = """
            {"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","kind":"audio-library","title":"1","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],
            "relationships":[{"kind":"audio","label":"Tracks","entities":[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","kind":"audio","title":"Let It Be","sortOrder":1,"hasSourceMedia":true}]}]}
            """
        let detail = try JSONDecoder().decode(EntityDetail.self, from: Data(json.utf8))

        let tracks = MusicEntityProjection.tracks(in: detail)

        XCTAssertEqual(tracks.map(\.title), ["Let It Be"])
        XCTAssertEqual(tracks.first?.album, "1")
    }

    func testLibraryTrackProjectionHydratesAlbumArtistAndInheritedArtwork() {
        let artistID = UUID()
        let albumID = UUID()
        let trackID = UUID()
        let track = EntityThumbnail(
            id: trackID,
            kind: .audioTrack,
            title: "Shots",
            parentEntityID: albumID,
            meta: [.init(icon: "duration", label: "03:52")]
        )
        let album = EntityThumbnail(
            id: albumID,
            kind: .audioLibrary,
            title: "Smoke + Mirrors",
            parentEntityID: artistID,
            coverURL: "/assets/smoke.jpg"
        )
        let artist = EntityThumbnail(id: artistID, kind: .musicArtist, title: "Imagine Dragons")

        let projected = MusicEntityProjection.libraryTracks(
            [track],
            albumsByID: [albumID: album],
            artistsByID: [artistID: artist]
        )

        XCTAssertEqual(projected.first?.id, trackID)
        XCTAssertEqual(projected.first?.album, "Smoke + Mirrors")
        XCTAssertEqual(projected.first?.artist, "Imagine Dragons")
        XCTAssertEqual(projected.first?.artworkPath, "/assets/smoke.jpg")
        XCTAssertEqual(projected.first?.duration, 232)
    }
}
