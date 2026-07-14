import Foundation
import XCTest

final class PluginSearchSurfaceContractTests: XCTestCase {
    func testSurfaceUsesTheSharedPolicyAndExtractedNativeComponents() throws {
        let source = try sourceFile("PrismediaShared/Features/PluginDiscovery/Components/PluginSearchSurface.swift")

        XCTAssertTrue(source.contains("PluginSearchFieldPolicy.eligibleProviders"))
        XCTAssertTrue(source.contains("PluginSearchFieldPolicy.hasRequiredValues"))
        XCTAssertTrue(source.contains("PluginSearchFieldPolicy.submittedValues"))
        XCTAssertTrue(source.contains("PluginSearchFieldControl("))
        XCTAssertTrue(source.contains("PluginCandidateCard("))
        XCTAssertTrue(source.contains("Picker("))
        XCTAssertTrue(
            source.contains("isBestMatch: candidate.pluginSearchIdentity == candidates.first?.pluginSearchIdentity"))
    }

    func testEveryPluginSearchViewIsCompileGatedAwayFromTVOS() throws {
        for path in [
            "PrismediaShared/Features/PluginDiscovery/Components/PluginSearchSurface.swift",
            "PrismediaShared/Features/PluginDiscovery/Components/PluginSearchFieldControl.swift",
            "PrismediaShared/Features/PluginDiscovery/Components/PluginCandidateCard.swift",
        ] {
            XCTAssertTrue(
                try sourceFile(path).contains("#if os(iOS) || os(macOS)"),
                "\(path) must exclude tvOS at compile time."
            )
        }
    }

    func testCandidateCardUsesAFullWidthButtonHitTarget() throws {
        let source = try sourceFile("PrismediaShared/Features/PluginDiscovery/Components/PluginCandidateCard.swift")

        XCTAssertTrue(source.contains("Button"))
        XCTAssertTrue(source.contains("maxWidth: .infinity"))
        XCTAssertTrue(source.contains("contentShape(Rectangle())"))
        XCTAssertTrue(source.contains("Best Match"))
        XCTAssertFalse(source.contains("onTapGesture"))
    }

    private func sourceFile(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(contentsOf: repositoryRoot.appending(path: relativePath), encoding: .utf8)
    }
}
