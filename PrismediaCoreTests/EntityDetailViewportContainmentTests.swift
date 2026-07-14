import SwiftUI
import XCTest

@testable import PrismediaCore

final class EntityDetailViewportContainmentTests: XCTestCase {
    func testLoadedArtworkAtmosphereCannotParticipateInDetailWidthNegotiation() throws {
        let detailView = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )

        XCTAssertTrue(detailView.contains("EntityDetailArtworkSurface("))
        XCTAssertFalse(detailView.contains("ArtworkPaletteSurface("))

        let artworkSurface = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailArtworkSurface.swift"
        )
        XCTAssertTrue(artworkSurface.contains(".background"))
        XCTAssertTrue(artworkSurface.contains("GeometryReader"))
        XCTAssertTrue(artworkSurface.contains("width: geometry.size.width"))
    }

    @MainActor
    func testHeroInformationAcceptsANarrowPhoneWidthProposal() throws {
        let presentation = EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail)
        let view = PreviewShell {
            EntityDetailHeroInformationView(
                presentation: presentation,
                previewPath: "/preview/poster.jpg",
                showsArtwork: true,
                actions: presentation.primaryActions,
                isMutating: false,
                canMutate: true,
                isActionEnabled: { _ in true },
                actionHint: { _ in "Opens this item" },
                onRatingChange: { _ in },
                onAction: { _ in }
            )
        }
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(width: 320, height: nil)
        renderer.scale = 1

        let image = try XCTUnwrap(renderer.cgImage)

        XCTAssertEqual(image.width, 320)
    }

    private func sourceFile(_ path: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: root.appending(path: path),
            encoding: .utf8
        )
    }
}
