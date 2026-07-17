import Foundation

public struct AdministrativeUploadItemCollector: Sendable {
    public init() {}

    public func collect(_ urls: [URL]) throws -> [AdministrativeFileUploadItem] {
        try urls.flatMap { url in
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            guard values.isDirectory == true else {
                return [AdministrativeFileUploadItem(localURL: url, relativePath: url.lastPathComponent, securityScopeURL: url)]
            }
            return try collectDirectory(url)
        }
    }

    private func collectDirectory(_ root: URL) throws -> [AdministrativeFileUploadItem] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        let base = root.deletingLastPathComponent().standardizedFileURL.path
        return try enumerator.compactMap { value in
            guard let url = value as? URL else { return nil }
            let properties = try url.resourceValues(forKeys: Set(keys))
            guard properties.isRegularFile == true, properties.isSymbolicLink != true else { return nil }
            let path = url.standardizedFileURL.path
            guard path.hasPrefix(base + "/") else { throw AdministrativeFileValidationError.escapingPath }
            let relative = String(path.dropFirst(base.count + 1))
            return AdministrativeFileUploadItem(localURL: url, relativePath: relative, securityScopeURL: root)
        }
    }
}
