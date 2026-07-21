import Foundation
import XCTest

final class ModernArchitectureGuardTests: XCTestCase {
    func testAppAndFeatureLayersUseObservationBasedModelViewArchitecture() throws {
        let sourceFiles = try swiftFiles(in: [
            "PrismediaShared/App",
            "PrismediaShared/Features",
            "PrismediaShared/Presentation",
        ])
        let forbiddenPatterns = [
            "ObservableObject",
            "@Published",
            "@StateObject",
            "@ObservedObject",
            "@EnvironmentObject",
            "ViewModel",
            "EnvironmentKey",
            "AnyView",
        ]

        let violations = sourceFiles.flatMap { file -> [String] in
            let source = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
            return forbiddenPatterns.compactMap { pattern in
                source.contains(pattern) ? "\(relativePath(file)): \(pattern)" : nil
            }
        }

        XCTAssertEqual(
            violations,
            [],
            "App and feature code must use view-owned state, focused services, and Observation.\n"
                + violations.joined(separator: "\n")
        )
    }

    func testAppAndFeatureUIStaySwiftUIOnly() throws {
        let sourceFiles = try swiftFiles(in: [
            "PrismediaShared/App",
            "PrismediaShared/Features",
            "PrismediaShared/Presentation",
        ])
        let forbiddenImports = ["import UIKit", "import AppKit"]
        let violations = sourceFiles.flatMap { file -> [String] in
            let source = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
            return forbiddenImports.compactMap { legacyImport in
                source.contains(legacyImport)
                    ? "\(relativePath(file)): \(legacyImport)"
                    : nil
            }
        }

        XCTAssertEqual(
            violations,
            [],
            "Feature and shared UI code stays SwiftUI-only; required platform bridges belong under Infrastructure/PlatformAdapters.\n"
                + violations.joined(separator: "\n")
        )
    }

    func testProductionFilesDeclareAtMostOneTopLevelType() throws {
        let sourceFiles = try swiftFiles(in: [
            "PrismediaShared",
            "PrismediaiOS",
            "PrismediaMac",
            "PrismediaTV",
        ])
        let declarationPattern = try NSRegularExpression(
            pattern:
                #"^(?:(?:public|internal|package|private|fileprivate|open|final|indirect|nonisolated)\s+)*(?:struct|class|enum|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)"#,
            options: [.anchorsMatchLines]
        )

        let violations = sourceFiles.compactMap { file -> String? in
            guard let source = try? String(contentsOf: file, encoding: .utf8) else {
                return nil
            }
            let range = NSRange(source.startIndex..., in: source)
            let declaredNames = Set(
                declarationPattern.matches(in: source, range: range).compactMap { match -> String? in
                    guard let nameRange = Range(match.range(at: 1), in: source) else {
                        return nil
                    }
                    return String(source[nameRange])
                }
            )

            return declaredNames.count > 1
                ? "\(relativePath(file)): \(declaredNames.count) top-level types"
                : nil
        }

        XCTAssertEqual(
            violations,
            [],
            "Keep each production enum, struct, class, actor, or protocol in its own file.\n"
                + violations.joined(separator: "\n")
        )
    }

    func testSharedSourcesDoNotContainWholeFileSinglePlatformImplementations() throws {
        let sourceFiles = try swiftFiles(in: ["PrismediaShared"])
        let singlePlatformCondition = try NSRegularExpression(
            pattern: #"^#if os\((?:iOS|macOS|tvOS)\)(?: && .*)?$"#,
            options: [.anchorsMatchLines]
        )

        let violations = sourceFiles.compactMap { file -> String? in
            guard let source = try? String(contentsOf: file, encoding: .utf8) else {
                return nil
            }
            let range = NSRange(source.startIndex..., in: source)
            guard singlePlatformCondition.firstMatch(in: source, range: range) != nil else {
                return nil
            }

            let topLevelAlternatives = source.split(separator: "\n").contains { line in
                line.hasPrefix("#else")
            }
            let lastDirective = source.split(whereSeparator: \Character.isWhitespace).last
            guard !topLevelAlternatives, lastDirective == "#endif" else { return nil }

            return relativePath(file)
        }
        .sorted()

        XCTAssertEqual(
            violations,
            [],
            "Move whole-file single-platform implementations into the matching app target.\n"
                + violations.joined(separator: "\n")
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func swiftFiles(in directories: [String]) throws -> [URL] {
        try directories.flatMap { directory in
            let root = repositoryRoot.appending(path: directory)
            guard
                let enumerator = FileManager.default.enumerator(
                    at: root,
                    includingPropertiesForKeys: [.isRegularFileKey]
                )
            else {
                throw CocoaError(.fileReadNoSuchFile)
            }

            return enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        }
    }

    private func relativePath(_ file: URL) -> String {
        file.path.replacingOccurrences(of: repositoryRoot.path + "/", with: "")
    }
}
