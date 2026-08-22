import XCTest

@testable import PrismediaCore

final class BookReaderManifestResolverTests: XCTestCase {
    func testManifestResourcesResumeWithoutPageEntities() async throws {
        let installmentID = UUID(uuidString: "01000000-0000-0000-0000-000000000000")!
        let detail = installment(
            id: installmentID,
            progress: .init(
                currentEntityID: installmentID,
                unit: .page,
                index: 1,
                total: 2,
                mode: .webtoon,
                completedAt: nil,
                updatedAt: nil,
                workIndex: 1,
                workTotal: 2,
                location: nil
            )
        )
        let source = readerManifest(entityID: installmentID, pageCount: 2)
        let loader = ManifestEntityLoader(values: [installmentID: detail], manifests: [installmentID: source])

        let manifest = try await BookReaderManifestResolver(loader: loader).resolve(
            selected: detail,
            command: .resume
        )

        XCTAssertEqual(manifest.bookID, installmentID)
        XCTAssertEqual(manifest.initialIndex, 1)
        XCTAssertEqual(manifest.readerMode, .paged)
        XCTAssertEqual(manifest.readingDirection, .rightToLeft)
        XCTAssertEqual(manifest.pages.map(\.entityID), [installmentID, installmentID])
        XCTAssertEqual(manifest.pages.map(\.ordinal), [0, 1])
        XCTAssertTrue(manifest.pages[1].isDoublePage)
    }

    func testExplicitThumbnailSelectionOpensTheRequestedOrdinal() async throws {
        let installmentID = UUID()
        let detail = installment(id: installmentID)
        let source = readerManifest(entityID: installmentID, pageCount: 4)
        let loader = ManifestEntityLoader(values: [installmentID: detail], manifests: [installmentID: source])

        let manifest = try await BookReaderManifestResolver(loader: loader).resolve(
            selected: detail,
            command: .page(3)
        )

        XCTAssertEqual(manifest.initialIndex, 3)
    }

    func testPageSequenceContinuesAcrossOrderedComicVolumes() async throws {
        let seriesID = UUID()
        let firstVolumeID = UUID()
        let secondVolumeID = UUID()
        let selectedID = UUID()
        let nextID = UUID()
        let series = entity(
            id: seriesID,
            kind: .comicSeries,
            children: [group(.comicVolume, [
                thumbnail(firstVolumeID, .comicVolume, "Volume 1", order: 0, parent: seriesID),
                thumbnail(secondVolumeID, .comicVolume, "Volume 2", order: 1, parent: seriesID),
            ])]
        )
        let firstVolume = entity(
            id: firstVolumeID,
            kind: .comicVolume,
            parent: seriesID,
            children: [group(.comicInstallment, [
                thumbnail(selectedID, .comicInstallment, "Chapter 1", order: 0, parent: firstVolumeID)
            ])]
        )
        let secondVolume = entity(
            id: secondVolumeID,
            kind: .comicVolume,
            parent: seriesID,
            children: [group(.comicInstallment, [
                thumbnail(nextID, .comicInstallment, "Chapter 2", order: 0, parent: secondVolumeID)
            ])]
        )
        let selected = installment(id: selectedID, parent: firstVolumeID, ordered: true)
        let loader = ManifestEntityLoader(
            values: [
                seriesID: series,
                firstVolumeID: firstVolume,
                secondVolumeID: secondVolume,
                selectedID: selected,
            ],
            manifests: [selectedID: readerManifest(entityID: selectedID, pageCount: 1)]
        )

        let manifest = try await BookReaderManifestResolver(loader: loader).resolve(
            selected: selected,
            command: .read
        )

        XCTAssertEqual(manifest.nextChapter?.id, nextID)
    }

    func testBookChapterWithoutPageSequenceIsNotReadable() async {
        let chapter = entity(id: UUID(), kind: .bookChapter)
        let loader = ManifestEntityLoader(values: [chapter.id: chapter])

        do {
            _ = try await BookReaderManifestResolver(loader: loader).resolve(
                selected: chapter,
                command: .read
            )
            XCTFail("Expected prose chapter metadata to stay out of the page reader.")
        } catch let error as BookReaderManifestError {
            guard case .unsupportedEntity(.bookChapter) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func installment(
        id: UUID,
        parent: UUID? = nil,
        progress: EntityProgressCapability? = nil,
        ordered: Bool = false
    ) -> EntityDetail {
        var capabilities: [EntityCapability] = [
            .pageSequence(.init(
                pageCount: 4,
                direction: .rightToLeft,
                defaultMode: .paged,
                coverOrdinal: 0
            ))
        ]
        if ordered {
            capabilities.append(.orderedSequence(.init(
                role: .item,
                itemKind: .comicInstallment,
                containerKinds: [.comicSeries, .comicVolume]
            )))
        }
        if let progress { capabilities.append(.progress(progress)) }
        return entity(
            id: id,
            kind: .comicInstallment,
            parent: parent,
            capabilities: capabilities
        )
    }

    private func entity(
        id: UUID,
        kind: EntityKind,
        parent: UUID? = nil,
        capabilities: [EntityCapability] = [],
        children: [EntityGroup] = []
    ) -> EntityDetail {
        EntityDetail(
            id: id,
            kind: kind,
            title: kind.displayLabel,
            parentEntityID: parent,
            sortOrder: nil,
            hasSourceMedia: kind == .comicInstallment,
            capabilities: capabilities,
            childrenByKind: children,
            relationships: []
        )
    }

    private func readerManifest(entityID: UUID, pageCount: Int) -> EntityReaderManifest {
        EntityReaderManifest(
            entityID: entityID,
            direction: .rightToLeft,
            defaultMode: .webtoon,
            coverOrdinal: 0,
            pages: (0..<pageCount).map {
                EntityReaderManifestPage(
                    ordinal: $0,
                    mimeType: "image/jpeg",
                    isDoublePage: $0 == 1
                )
            }
        )
    }

    private func group(_ kind: EntityKind, _ entities: [EntityThumbnail]) -> EntityGroup {
        EntityGroup(kind: kind, label: kind.displayLabel, entities: entities, code: nil)
    }

    private func thumbnail(
        _ id: UUID,
        _ kind: EntityKind,
        _ title: String,
        order: Int,
        parent: UUID
    ) -> EntityThumbnail {
        EntityThumbnail(id: id, kind: kind, title: title, parentEntityID: parent, sortOrder: order)
    }
}

private struct ManifestEntityLoader: EntityPageReaderServicing {
    let values: [UUID: EntityDetail]
    let manifests: [UUID: EntityReaderManifest]

    init(values: [UUID: EntityDetail], manifests: [UUID: EntityReaderManifest] = [:]) {
        self.values = values
        self.manifests = manifests
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let detail = values[id] else { throw BookReaderManifestError.noReadablePages }
        return detail
    }

    func loadEntityReaderManifest(id: UUID) async throws -> EntityReaderManifest {
        guard let manifest = manifests[id] else { throw BookReaderManifestError.noReadablePages }
        return manifest
    }

    func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data {
        throw BookReaderManifestError.noReadablePages
    }
}
