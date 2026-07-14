import Foundation

public struct EPUBPublicationLoader: Sendable {
    public init() {}

    public func load(
        data: Data,
        fallbackTitle: String,
        destination: URL
    ) throws -> EPUBPublication {
        let entries = try EPUBZipArchiveReader().entries(in: data)
        guard entries["META-INF/encryption.xml"] == nil else {
            throw EPUBReaderError.unsupportedDRM
        }
        guard let containerData = entries["META-INF/container.xml"] else {
            throw EPUBReaderError.missingContainer
        }
        let packagePath = try parseContainer(containerData)
        guard let packageData = entries[packagePath] else {
            throw EPUBReaderError.missingPackageDocument
        }
        let package = try parsePackage(packageData)
        let packageDirectory = (packagePath as NSString).deletingLastPathComponent
        let tableOfContents = try parseTableOfContents(
            package: package,
            entries: entries,
            packageDirectory: packageDirectory
        )
        let chapters = try chapterItems(package).map { item in
            let location = try resolvedPath(base: packageDirectory, relative: item.href)
            guard entries[location] != nil else { throw EPUBReaderError.malformedPackageDocument }
            return (item, location)
        }
        guard !chapters.isEmpty else { throw EPUBReaderError.emptySpine }

        try extract(entries: entries, to: destination)
        return EPUBPublication(
            title: package.title ?? fallbackTitle,
            chapters: chapters.map { item, location in
                EPUBChapter(
                    id: item.id,
                    location: relativePath(location, from: packageDirectory),
                    fileURL: destination.appending(path: location)
                )
            },
            tableOfContents: tableOfContents,
            rootURL: destination
        )
    }

    private func parseContainer(_ data: Data) throws -> String {
        let delegate = EPUBContainerXMLDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false
        guard parser.parse(), let path = delegate.packagePath else {
            throw EPUBReaderError.missingPackageDocument
        }
        return try resolvedPath(base: "", relative: path)
    }

    private func parsePackage(_ data: Data) throws -> EPUBPackageXMLDelegate {
        let delegate = EPUBPackageXMLDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false
        guard parser.parse() else { throw EPUBReaderError.malformedPackageDocument }
        return delegate
    }

    private func chapterItems(_ package: EPUBPackageXMLDelegate) throws -> [EPUBManifestItem] {
        let chapters: [EPUBManifestItem] = package.spine.compactMap { id -> EPUBManifestItem? in
            guard let item = package.manifest[id],
                item.mediaType == "application/xhtml+xml" || item.mediaType == "text/html"
            else { return nil }
            return item
        }
        guard chapters.count == package.spine.count else {
            throw EPUBReaderError.malformedPackageDocument
        }
        return chapters
    }

    private func parseTableOfContents(
        package: EPUBPackageXMLDelegate,
        entries: [String: Data],
        packageDirectory: String
    ) throws -> [EPUBTableOfContentsItem] {
        guard let item = package.manifest.values.first(where: { $0.properties.contains("nav") }) else {
            return []
        }
        let navigationPath = try resolvedPath(base: packageDirectory, relative: item.href)
        guard let data = entries[navigationPath] else { return [] }
        let delegate = EPUBNavigationDocumentDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false
        guard parser.parse() else { throw EPUBReaderError.malformedPackageDocument }

        let navigationDirectory = (navigationPath as NSString).deletingLastPathComponent
        let rows = try delegate.entries.map { row in
            let fragment = row.href.split(separator: "#", maxSplits: 1).dropFirst().first.map(String.init)
            let path = try resolvedPath(base: navigationDirectory, relative: row.href)
            let relative = relativePath(path, from: packageDirectory)
            return (
                title: row.title,
                location: fragment.map { "\(relative)#\($0)" } ?? relative,
                depth: row.depth
            )
        }
        var index = 0
        return buildTableOfContents(rows, level: 0, index: &index)
    }

    private func buildTableOfContents(
        _ rows: [(title: String, location: String, depth: Int)],
        level: Int,
        index: inout Int
    ) -> [EPUBTableOfContentsItem] {
        var items: [EPUBTableOfContentsItem] = []
        while index < rows.count {
            let row = rows[index]
            if row.depth < level { break }
            if row.depth > level { break }
            index += 1
            let children = buildTableOfContents(rows, level: level + 1, index: &index)
            items.append(
                EPUBTableOfContentsItem(
                    title: row.title,
                    location: row.location,
                    children: children
                )
            )
        }
        return items
    }

    private func extract(
        entries: [String: Data],
        to destination: URL
    ) throws {
        let manager = FileManager.default
        try? manager.removeItem(at: destination)
        try manager.createDirectory(at: destination, withIntermediateDirectories: true)
        let sanitizer = EPUBMarkupSanitizer()
        for (path, data) in entries {
            let target = destination.appending(path: path)
            try manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            let extensionName = target.pathExtension.lowercased()
            let extracted =
                extensionName == "xhtml" || extensionName == "html"
                ? try sanitizer.sanitize(data)
                : data
            // The extraction root is recreated before every load, so each
            // target is new. A second atomic-replacement temp file adds no
            // integrity benefit here and can race Foundation's temporary-file
            // cleanup under parallel test/app activity.
            try extracted.write(to: target)
        }
    }

    private func resolvedPath(base: String, relative: String) throws -> String {
        let withoutFragment = relative.split(separator: "#", maxSplits: 1).first.map(String.init) ?? relative
        let decoded = withoutFragment.removingPercentEncoding ?? withoutFragment
        let combined = base.isEmpty ? decoded : "\(base)/\(decoded)"
        var components: [Substring] = []
        for component in combined.replacingOccurrences(of: "\\", with: "/").split(separator: "/") {
            if component == "." { continue }
            if component == ".." {
                guard !components.isEmpty else { throw EPUBReaderError.unsafeArchivePath(relative) }
                components.removeLast()
                continue
            }
            components.append(component)
        }
        guard !decoded.hasPrefix("/"), !components.isEmpty else {
            throw EPUBReaderError.unsafeArchivePath(relative)
        }
        return components.joined(separator: "/")
    }

    private func relativePath(_ path: String, from directory: String) -> String {
        guard !directory.isEmpty, path.hasPrefix(directory + "/") else { return path }
        return String(path.dropFirst(directory.count + 1))
    }
}
