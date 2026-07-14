import Foundation
import SwiftUI
import XCTest

@testable import PrismediaCore

final class PrismediaDesignTokenTests: XCTestCase {
    func testSpacingScaleUsesTheCanonicalProgression() {
        XCTAssertEqual(PrismediaSpacing.extraExtraSmall, 2)
        XCTAssertEqual(PrismediaSpacing.extraSmall, 4)
        XCTAssertEqual(PrismediaSpacing.small, 8)
        XCTAssertEqual(PrismediaSpacing.medium, 12)
        XCTAssertEqual(PrismediaSpacing.large, 16)
        XCTAssertEqual(PrismediaSpacing.extraLarge, 20)
        XCTAssertEqual(PrismediaSpacing.extraExtraLarge, 24)
        XCTAssertEqual(PrismediaSpacing.section, 32)
        XCTAssertEqual(PrismediaSpacing.screen, 40)
    }

    func testSmallSurfaceMetricsHaveNamedTokens() {
        XCTAssertEqual(PrismediaRadius.badge, 6)
        XCTAssertEqual(PrismediaLayout.hairline, 1)
        XCTAssertEqual(PrismediaLayout.focusRing, 3)
        XCTAssertEqual(PrismediaLayout.backdropBlur, 72)
        XCTAssertEqual(PrismediaLayout.backdropOverscan, 1.16)
    }

    func testTypographyExposesTheSharedContentRoles() {
        let roles: [Font] = [
            PrismediaTypography.screenTitle,
            PrismediaTypography.sectionTitle,
            PrismediaTypography.subsectionTitle,
            PrismediaTypography.cardTitle,
            PrismediaTypography.body,
            PrismediaTypography.metadata,
            PrismediaTypography.caption,
            PrismediaTypography.captionEmphasized,
            PrismediaTypography.compactCaption,
            PrismediaTypography.compactCaptionEmphasized,
            PrismediaTypography.numericCaption,
            PrismediaTypography.badge,
        ]

        XCTAssertEqual(roles.count, 12)
    }

    func testVisualSourcesUseNamedLayoutTokens() throws {
        let sourceRoot = repositoryRoot.appending(path: "PrismediaShared")
        let files = FileManager.default.enumerator(
            at: sourceRoot,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        let layoutExpression = try NSRegularExpression(
            pattern:
                #"(?:spacing:\s*|\.padding\(\s*(?:\.[A-Za-z]+|\[[^\]]+\])?\s*,?\s*)(?:[1-9]|[12]\d|3\d|40)\b|(?:cornerRadius:\s*|\.cornerRadius\()(?:[1-9]|1\d|2[0-4])\b"#
        )

        let violations = try (files?.compactMap { $0 as? URL } ?? []).compactMap { file -> String? in
            guard file.pathExtension == "swift" else { return nil }
            guard !file.pathComponents.contains("Tokens") else { return nil }

            let source = try String(contentsOf: file, encoding: .utf8)
            let isVisualSource =
                source.contains(": View")
                || source.contains(": ViewModifier")
                || source.contains("extension View")
            guard isVisualSource else { return nil }

            let range = NSRange(source.startIndex..., in: source)
            guard layoutExpression.firstMatch(in: source, range: range) != nil else { return nil }
            return file.path.replacingOccurrences(of: repositoryRoot.path + "/", with: "")
        }.sorted()

        XCTAssertEqual(
            violations,
            [],
            "Small visual layout values belong in PrismediaSpacing or PrismediaRadius. "
                + "Keep feature-specific geometry named locally.\n"
                + violations.joined(separator: "\n")
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
