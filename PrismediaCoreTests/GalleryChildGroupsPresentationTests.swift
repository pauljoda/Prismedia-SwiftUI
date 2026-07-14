import XCTest

@testable import PrismediaCore

final class GalleryChildGroupsPresentationTests: XCTestCase {
    func testEnhancedChildSectionsAreExclusiveToGalleryDetails() {
        XCTAssertTrue(GalleryChildGroupsPresentation.isAvailable(for: .gallery))
        XCTAssertFalse(GalleryChildGroupsPresentation.isAvailable(for: .image))
        XCTAssertFalse(GalleryChildGroupsPresentation.isAvailable(for: .movie))
    }

    func testGallerySectionsPutSubGalleriesBeforeImagesRegardlessOfServerOrder() {
        let image = thumbnail(id: 1, kind: .image, title: "Still")
        let subGallery = thumbnail(id: 2, kind: .gallery, title: "Portraits")
        let tag = thumbnail(id: 3, kind: .tag, title: "Featured")
        let groups = [
            EntityGroup(kind: .image, label: "Images", entities: [image], code: "images"),
            EntityGroup(kind: .tag, label: "Tags", entities: [tag], code: "tags"),
            EntityGroup(kind: .gallery, label: "Galleries", entities: [subGallery], code: "galleries"),
        ]

        let presentation = GalleryChildGroupsPresentation(
            galleryID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            groups: groups
        )

        XCTAssertEqual(presentation.subGalleries, [subGallery])
        XCTAssertEqual(presentation.images, [image])
        XCTAssertEqual(presentation.remainingGroups, [groups[1]])
    }

    func testRealImagesGroupPayloadProjectsItsNonzeroImageEntities() throws {
        let payload = Data(
            #"""
            {
              "kind": "image",
              "label": "Images",
              "entities": [{
                "id": "11111111-1111-1111-1111-111111111111",
                "kind": "image",
                "title": "Scanned Still",
                "parentEntityId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                "parentKind": "gallery",
                "sortOrder": 0,
                "isNsfw": true,
                "hasSourceMedia": true
              }]
            }
            """#.utf8
        )
        let group = try PrismediaJSON.decoder().decode(EntityGroup.self, from: payload)

        let presentation = GalleryChildGroupsPresentation(
            galleryID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            groups: [group]
        )

        XCTAssertEqual(presentation.images.count, 1)
        XCTAssertEqual(presentation.images.first?.kind, .image)
        XCTAssertEqual(presentation.images.first?.parentKind, .gallery)
    }

    func testGalleryImageGridStartsAsMediaWallAndKeepsPreferencesPerGallery() {
        let galleryID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let presentation = GalleryChildGroupsPresentation(galleryID: galleryID, groups: [])

        let configuration = presentation.imageGridConfiguration

        XCTAssertEqual(configuration.title, "Images")
        XCTAssertEqual(configuration.query.kind, .image)
        XCTAssertEqual(configuration.defaultDisplayMode, .wall)
        XCTAssertEqual(configuration.preferencesID, "gallery-\(galleryID.uuidString.lowercased())-images")
    }

    func testGalleryGroupsFlattenRepeatedServerBucketsWithoutDuplicatingEntities() {
        let first = thumbnail(id: 1, kind: .image, title: "First")
        let second = thumbnail(id: 2, kind: .image, title: "Second")
        let groups = [
            EntityGroup(kind: .image, label: "Images", entities: [first], code: "images-a"),
            EntityGroup(kind: .image, label: "More Images", entities: [first, second], code: "images-b"),
        ]

        let presentation = GalleryChildGroupsPresentation(galleryID: UUID(), groups: groups)

        XCTAssertEqual(presentation.images, [first, second])
    }

    private func thumbnail(id: Int, kind: EntityKind, title: String) -> EntityThumbnail {
        EntityThumbnail(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            kind: kind,
            title: title
        )
    }
}
