import XCTest

@testable import PrismediaCore

final class MusicPresentationTests: XCTestCase {
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
