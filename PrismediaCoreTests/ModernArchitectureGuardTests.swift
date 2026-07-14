import Foundation
import XCTest

final class ModernArchitectureGuardTests: XCTestCase {
    func testAppAndFeatureLayersUseObservationBasedModelViewArchitecture() throws {
        let sourceFiles = try swiftFiles(in: [
            "PrismediaShared/App",
            "PrismediaShared/Features",
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
                source.contains(pattern)
                    ? "\(relativePath(file)): \(pattern)"
                    : nil
            }
        }

        XCTAssertEqual(
            violations,
            [],
            "App and feature code must use view-owned state, focused services, and Observation.\n\(violations.joined(separator: "\n"))"
        )
    }

    func testRuntimeRootForcesTheSingleDarkAppearance() throws {
        let root =
            repositoryRoot
            .appending(path: "PrismediaShared/App/PrismediaRootView.swift")
        let source = try String(contentsOf: root, encoding: .utf8)
        let runtimeSource = source.components(separatedBy: "#if DEBUG").first ?? source

        XCTAssertTrue(
            runtimeSource.contains(".preferredColorScheme(.dark)"),
            "Prismedia intentionally presents one dark app appearance on every platform."
        )
    }

    func testEntityDetailUsesExplicitCapabilityComposition() throws {
        let relativePaths = [
            "PrismediaShared/Features/EntityDetail/EntityDetailView.swift",
            "PrismediaShared/Features/EntityDetail/Services/EntityDetailService.swift",
        ]
        let sources = try relativePaths.map { path in
            try String(
                contentsOf: repositoryRoot.appending(path: path),
                encoding: .utf8
            )
        }

        XCTAssertTrue(sources[0].contains("EntityDetailDependencies"))
        XCTAssertFalse(sources[0].contains("PrismediaAppEnvironment"))
        XCTAssertFalse(sources[0].contains("as? any"))
        XCTAssertFalse(sources[0].contains("init(link: EntityLink, loader:"))
        XCTAssertFalse(sources[1].contains("as? any"))
        XCTAssertFalse(sources[1].contains("loader is any EntityDetailMutating"))
    }

    func testOrdinaryThumbnailCardsUseTheSharedNavigationSurface() throws {
        let relativePaths = [
            "PrismediaShared/App/Shell/PrismediaShellView.swift",
            "PrismediaShared/App/Shell/PrismediaTVShellView.swift",
            "PrismediaShared/Features/Dashboard/DashboardView.swift",
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailChildGroupsView.swift",
            "PrismediaShared/Features/EntityDetail/Components/EntityDetailSectionPanel.swift",
            "PrismediaShared/Features/Television/Components/TVHomeShelfSection.swift",
        ]

        let violations = try relativePaths.compactMap { path -> String? in
            let source = try String(
                contentsOf: repositoryRoot.appending(path: path),
                encoding: .utf8
            )
            return source.contains("EntityThumbnailCardView(item: item") ? path : nil
        }

        XCTAssertEqual(
            violations,
            [],
            "Ordinary thumbnail cards must route through EntityThumbnailNavigationSurface."
        )

        let navigationSurface = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/UI/Components/EntityThumbnailNavigationSurface.swift"
            ),
            encoding: .utf8
        )
        XCTAssertTrue(navigationSurface.contains("onPreviewHoldChanged: previewHoldDidChange"))
        XCTAssertTrue(navigationSurface.contains("router.open("))
        XCTAssertTrue(navigationSurface.contains("within: item.kind == .image ? mediaSequence : nil"))

    }

    func testThumbnailPreviewDoesNotCaptureTouchScrolling() throws {
        let source = try String(
            contentsOf: repositoryRoot.appending(
                path: "PrismediaShared/UI/Components/EntityThumbnailMediaView.swift"
            ),
            encoding: .utf8
        )

        XCTAssertFalse(
            source.contains("DragGesture"),
            "Thumbnail previews must not compete with touch scrolling."
        )
        XCTAssertTrue(
            source.contains("#if os(macOS)"),
            "Position-based thumbnail previewing is a desktop pointer interaction."
        )
        XCTAssertTrue(
            source.contains(".onLongPressGesture("),
            "Touch thumbnails should use a stationary hold-to-preview interaction."
        )
    }

    func testAppAndFeatureUIStaySwiftUIOnly() throws {
        let sourceFiles = try swiftFiles(in: [
            "PrismediaShared/App",
            "PrismediaShared/Features",
            "PrismediaShared/UI",
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
            "Feature and shared UI code stays SwiftUI-only; required platform bridges belong under Infrastructure/PlatformAdapters.\n\(violations.joined(separator: "\n"))"
        )
    }

    func testFeatureSlicesUseTheVerticalModuleLayout() {
        let expectedFeatures = [
            "Administration",
            "Audiobook",
            "Authentication",
            "Collections",
            "Dashboard",
            "EntityDetail",
            "EntityGrid",
            "Identify",
            "ImageViewer",
            "Manage",
            "MetadataReview",
            "Playback",
            "PlaybackStatistics",
            "PluginDiscovery",
            "Reader",
            "Request",
            "RequestActivity",
            "Search",
            "Television",
        ]
        let featuresRoot = repositoryRoot.appending(path: "PrismediaShared/Features")

        for feature in expectedFeatures {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(
                atPath: featuresRoot.appending(path: feature).path,
                isDirectory: &isDirectory
            )
            XCTAssertTrue(exists && isDirectory.boolValue, "Missing feature slice: \(feature)")
        }

        for legacyDirectory in ["Scenes", "Reader", "Playback"] {
            XCTAssertFalse(
                FileManager.default.fileExists(
                    atPath:
                        repositoryRoot
                        .appending(path: "PrismediaShared")
                        .appending(path: legacyDirectory)
                        .path
                ),
                "Move \(legacyDirectory) into App or a vertical feature slice."
            )
        }
    }

    func testFeatureFoldersSeparateScreensComponentsModelsServicesAndSupport() throws {
        let featuresRoot = repositoryRoot.appending(path: "PrismediaShared/Features")
        let featureDirectories = try childDirectories(of: featuresRoot)
        var violations: [String] = []

        for featureDirectory in featureDirectories {
            let rootFiles = try directSwiftFiles(in: featureDirectory)
            for file in rootFiles where try !declaresVisualType(in: file) {
                violations.append(
                    "\(relativePath(file)): feature roots are reserved for screen Views"
                )
            }

            for directoryName in ["Models", "Services", "Support"] {
                let directories = try descendantDirectories(
                    named: directoryName,
                    under: featureDirectory
                )
                for directory in directories {
                    for file in try directSwiftFiles(in: directory)
                    where try declaresVisualType(in: file) {
                        violations.append(
                            "\(relativePath(file)): visual types belong in Components or the feature root"
                        )
                    }
                }
            }

            let componentDirectories = try descendantDirectories(
                named: "Components",
                under: featureDirectory
            )
            for directory in componentDirectories {
                for file in try directSwiftFiles(in: directory)
                where try !declaresVisualType(in: file) {
                    violations.append(
                        "\(relativePath(file)): Components is reserved for visual types"
                    )
                }
            }
        }

        XCTAssertEqual(
            violations.sorted(),
            [],
            "Keep feature screens, visual components, models, services, and support code in explicit vertical folders.\n"
                + violations.sorted().joined(separator: "\n")
        )
    }

    func testSharedUIRootContainsOnlyVisualTypes() throws {
        let uiRoot = repositoryRoot.appending(path: "PrismediaShared/UI")
        let violations = try directSwiftFiles(in: uiRoot).compactMap { file -> String? in
            try declaresVisualType(in: file) || source(of: file).contains("extension View")
                ? nil
                : "\(relativePath(file)): move data or helpers into Models, Services, or Support"
        }

        XCTAssertEqual(
            violations.sorted(),
            [],
            "The shared UI root is a visual surface; keep nonvisual responsibilities in named subfolders.\n"
                + violations.sorted().joined(separator: "\n")
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
                declarationPattern.matches(
                    in: source,
                    range: range
                ).compactMap { match -> String? in
                    guard let nameRange = Range(match.range(at: 1), in: source) else {
                        return nil
                    }
                    return String(source[nameRange])
                })

            return declaredNames.count > 1
                ? "\(relativePath(file)): \(declaredNames.count) top-level types"
                : nil
        }

        XCTAssertEqual(
            violations,
            [],
            "Keep each production enum, struct, class, actor, or protocol in its own file. "
                + "Place feature-local data shapes in that feature's Models or Support folder, "
                + "and promote only genuinely shared types.\n"
                + violations.joined(separator: "\n")
        )
    }

    func testViewFilesDoNotHideAdditionalTypes() throws {
        let sourceFiles = try swiftFiles(in: [
            "PrismediaShared",
            "PrismediaiOS",
            "PrismediaMac",
            "PrismediaTV",
        ])
        let topLevelViewPattern = try NSRegularExpression(
            pattern:
                #"^(?:(?:public|internal|package|private|fileprivate|open|final|nonisolated)\s+)*struct\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s*[^\n{]*\bView\b"#,
            options: [.anchorsMatchLines]
        )
        let anyTypePattern = try NSRegularExpression(
            pattern:
                #"^\s*(?:(?:public|internal|package|private|fileprivate|open|final|indirect|nonisolated)\s+)*(?:struct|class|enum|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)"#,
            options: [.anchorsMatchLines]
        )

        let violations = sourceFiles.compactMap { file -> String? in
            guard let source = try? String(contentsOf: file, encoding: .utf8) else {
                return nil
            }
            let range = NSRange(source.startIndex..., in: source)
            guard topLevelViewPattern.firstMatch(in: source, range: range) != nil else {
                return nil
            }

            let declaredNames = Set(
                anyTypePattern.matches(in: source, range: range).compactMap { match -> String? in
                    guard let nameRange = Range(match.range(at: 1), in: source) else {
                        return nil
                    }
                    return String(source[nameRange])
                })
            return declaredNames.count > 1
                ? "\(relativePath(file)): \(declaredNames.count) total types"
                : nil
        }

        XCTAssertEqual(
            violations,
            [],
            "A view source file should expose the view object without hiding data shapes or helper objects inside it.\n"
                + violations.joined(separator: "\n")
        )
    }

    func testProductionTypeFileNameMatchesDeclaration() throws {
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
            guard
                let match = declarationPattern.firstMatch(in: source, range: range),
                let nameRange = Range(match.range(at: 1), in: source)
            else {
                return nil
            }

            let declaredName = String(source[nameRange])
            let fileName = file.deletingPathExtension().lastPathComponent
            return declaredName == fileName
                ? nil
                : "\(relativePath(file)): declares \(declaredName)"
        }

        XCTAssertEqual(
            violations,
            [],
            "Name each production type's source file after that type so it is directly discoverable.\n"
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

            return
                enumerator
                .compactMap { $0 as? URL }
                .filter { $0.pathExtension == "swift" }
        }
    }

    private func childDirectories(of root: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey]
        ).filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
    }

    private func descendantDirectories(named name: String, under root: URL) throws -> [URL] {
        guard
            let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
        else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        return enumerator.compactMap { item -> URL? in
            guard let url = item as? URL, url.lastPathComponent == name else { return nil }
            return url
        }
    }

    private func directSwiftFiles(in directory: URL) throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        ).filter { $0.pathExtension == "swift" }
    }

    private func declaresVisualType(in file: URL) throws -> Bool {
        let source = try source(of: file)
        let expression = try NSRegularExpression(
            pattern:
                #"^\s*(?:(?:public|internal|package|private|fileprivate|open|final|nonisolated)\s+)*(?:struct|class|enum)\s+[A-Za-z_][A-Za-z0-9_]*(?:<[^\n{]*>)?\s*:\s*[^\n{]*\b(?:View|ToolbarContent|ViewModifier|ButtonStyle|PrimitiveButtonStyle|LabelStyle|ProgressViewStyle|ToggleStyle|GaugeStyle|ControlGroupStyle|DisclosureGroupStyle|GroupBoxStyle|MenuStyle|PickerStyle|TextFieldStyle|FormStyle|Shape|Layout|UIViewRepresentable|NSViewRepresentable|UIViewControllerRepresentable|NSViewControllerRepresentable|UIView|NSView|UIViewController|NSViewController|AVPlayerViewController)\b"#,
            options: [.anchorsMatchLines]
        )
        let range = NSRange(source.startIndex..., in: source)
        return expression.firstMatch(in: source, range: range) != nil
    }

    private func source(of file: URL) throws -> String {
        try String(contentsOf: file, encoding: .utf8)
    }

    private func relativePath(_ file: URL) -> String {
        file.path.replacingOccurrences(
            of: repositoryRoot.path + "/",
            with: ""
        )
    }
}
