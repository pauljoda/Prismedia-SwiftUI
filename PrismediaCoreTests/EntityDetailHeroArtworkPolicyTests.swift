import SwiftUI
import XCTest

@testable import PrismediaCore

final class EntityDetailHeroArtworkPolicyTests: XCTestCase {
    func testDecorativeBackdropFillsItsWideFrameWithoutLetterboxingPosterFallbacks() {
        XCTAssertEqual(EntityDetailHeroArtworkPolicy.contentMode, .fill)
    }

    func testInformationContinuationPrefersTheDedicatedHeroArtwork() {
        XCTAssertEqual(
            EntityDetailHeroArtworkPolicy.atmospherePath(
                heroPath: "/assets/hero.jpg",
                posterPath: "/assets/poster.jpg"
            ),
            "/assets/hero.jpg"
        )
    }

    func testInformationContinuationFallsBackToPosterArtworkWithoutInventingAHero() {
        XCTAssertEqual(
            EntityDetailHeroArtworkPolicy.atmospherePath(
                heroPath: nil,
                posterPath: "/assets/poster.jpg"
            ),
            "/assets/poster.jpg"
        )
    }

    func testHeroSummaryKeepsAtLeastSixDescriptionLinesReadable() {
        XCTAssertGreaterThanOrEqual(EntityDetailHeroArtworkPolicy.summaryLineLimit, 6)
    }

    func testEntityDetailOnlyBuildsAHeroFromDedicatedBackdropArtwork() throws {
        let header = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailHeaderView.swift"
        )
        let hero = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailHeroView.swift"
        )

        XCTAssertTrue(header.contains("if showsArtwork, let heroPath = presentation.heroPath"))
        XCTAssertFalse(hero.contains("presentation.heroPath ?? presentation.posterPath"))
    }

    func testInformationAtmosphereUsesTheViewportContainedArtworkSurface() throws {
        let surface = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailArtworkSurface.swift"
        )

        XCTAssertTrue(surface.contains("ArtworkPaletteSurface("))
        XCTAssertTrue(surface.contains("GeometryReader"))
        XCTAssertFalse(surface.contains(".glassEffect"))
    }

    func testDescriptionAppearsInHeroSummaryWithoutRepeatingInDetailsPanel() throws {
        let identity = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailIdentityView.swift"
        )
        let detailsPanel = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailSectionPanel.swift"
        )

        XCTAssertTrue(identity.contains("if let description = presentation.description"))
        XCTAssertTrue(identity.contains("Text(description)"))
        XCTAssertFalse(detailsPanel.contains("Text(description)"))
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
