import Foundation
import XCTest

final class PreviewCoverageTests: XCTestCase {
    func testEveryVisualTypeHasADirectXcodePreview() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceDirectories = [
            "PrismediaShared",
            "PrismediaiOS",
            "PrismediaMac",
            "PrismediaTV",
        ]
        let sourceFiles = sourceDirectories.flatMap { directory -> [URL] in
            let sourceRoot = repositoryRoot.appending(path: directory)
            let files = FileManager.default.enumerator(
                at: sourceRoot,
                includingPropertiesForKeys: [.isRegularFileKey]
            )
            return files?.compactMap { $0 as? URL } ?? []
        }

        let previewViolations =
            try sourceFiles
            .filter { $0.pathExtension == "swift" }
            .flatMap { url -> [String] in
                let source = try String(contentsOf: url, encoding: .utf8)
                let visualTypeNames = try visualTypeNames(in: source)
                let extendsView = source.contains("extension View")
                guard !visualTypeNames.isEmpty || extendsView else { return [] }

                let relativePath = url.path.replacingOccurrences(
                    of: repositoryRoot.path + "/",
                    with: ""
                )
                guard let previewRange = source.range(of: "#Preview") else {
                    return ["\(relativePath): missing #Preview"]
                }

                let previewSource = String(source[previewRange.lowerBound...])
                return try visualTypeNames.compactMap { typeName in
                    try previewDirectlyReferences(typeName, in: previewSource)
                        ? nil
                        : "\(relativePath): preview does not render \(typeName) directly"
                }
            }
            .sorted()

        XCTAssertEqual(
            previewViolations,
            [],
            "Every visual type must have a deterministic, direct #Preview beside it.\n"
                + previewViolations.joined(separator: "\n")
        )
    }

    private func visualTypeNames(in source: String) throws -> [String] {
        let pattern =
            #"^\s*(?:(?:public|internal|package|private|fileprivate|open|final|nonisolated)\s+)*(?:struct|class|enum)\s+([A-Za-z_][A-Za-z0-9_]*)(?:<[^\n{]*>)?\s*:\s*[^\n{]*\b(?:View|ViewModifier|ButtonStyle|PrimitiveButtonStyle|LabelStyle|ProgressViewStyle|ToggleStyle|GaugeStyle|ControlGroupStyle|DisclosureGroupStyle|GroupBoxStyle|MenuStyle|PickerStyle|TextFieldStyle|FormStyle|Shape|Layout|UIViewRepresentable|NSViewRepresentable|UIViewControllerRepresentable|NSViewControllerRepresentable|UIView|NSView|UIViewController|NSViewController|AVPlayerViewController)\b"#
        let expression = try NSRegularExpression(
            pattern: pattern,
            options: [.anchorsMatchLines]
        )
        let range = NSRange(source.startIndex..., in: source)

        return expression.matches(in: source, range: range).compactMap { match in
            guard let nameRange = Range(match.range(at: 1), in: source) else { return nil }
            return String(source[nameRange])
        }
    }

    private func previewDirectlyReferences(_ typeName: String, in previewSource: String) throws -> Bool {
        let escapedName = NSRegularExpression.escapedPattern(for: typeName)
        let expression = try NSRegularExpression(
            pattern: #"\b"# + escapedName + #"\s*(?:\(|\{)"#
        )
        let range = NSRange(previewSource.startIndex..., in: previewSource)
        return expression.firstMatch(in: previewSource, range: range) != nil
    }
}
