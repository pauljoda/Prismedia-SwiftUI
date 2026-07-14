import Foundation
import XCTest

@testable import PrismediaCore

final class TVEntityDetailPresentationTests: XCTestCase {
    func testTelevisionMovieDetailUsesViewportBackdropWithoutInlineArtwork() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )

        XCTAssertTrue(source.contains("if detail.kind == .movie"))
        XCTAssertTrue(source.contains("TVEntityDetailBackdropSurface("))
        XCTAssertTrue(source.contains("showsHeroArtwork: false"))
        XCTAssertTrue(source.contains("ScrollViewReader { proxy in"))
        XCTAssertTrue(source.contains(".id(\"entity-detail.bottom\")"))
    }

    func testTelevisionBackdropHasHeroPosterAndSpectralFallbacks() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/EntityDetail/Components/TVEntityDetailBackdrop.swift"
        )

        XCTAssertTrue(source.contains("if let heroPath"))
        XCTAssertTrue(source.contains("RemotePosterImage("))
        XCTAssertTrue(source.contains("else if let fallbackArtworkPath = posterPath ?? previewPath"))
        XCTAssertTrue(source.contains("ArtworkPaletteSurface("))
        XCTAssertTrue(source.contains("PrismediaBackdrop()"))
    }

    func testTelevisionDoesNotApplyANavigationTitle() throws {
        let source = try sourceFile(
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift"
        )
        let platformGuard = try XCTUnwrap(source.range(of: "#if !os(tvOS)"))
        let navigationTitle = try XCTUnwrap(source.range(of: ".navigationTitle(navigationTitle)"))
        let guardEnd = try XCTUnwrap(
            source.range(of: "#endif", range: platformGuard.lowerBound..<source.endIndex)
        )

        XCTAssertLessThan(platformGuard.lowerBound, navigationTitle.lowerBound)
        XCTAssertLessThan(navigationTitle.lowerBound, guardEnd.lowerBound)
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
