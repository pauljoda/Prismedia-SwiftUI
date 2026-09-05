import Foundation

/// Keeps each export in an isolated temporary directory with a bounded cleanup path.
public struct AdministrativeDownloadStorage: Sendable {
    private let directory: URL

    public init(directory: URL = FileManager.default.temporaryDirectory.appending(path: "PrismediaDownloads")) {
        self.directory = directory.standardizedFileURL
    }

    public func store(_ data: Data, suggestedName: String) throws -> AdministrativeDownloadedFile {
        let name = suggestedName.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\\", with: "_")
        let ownedDirectory = directory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: ownedDirectory, withIntermediateDirectories: true)
        let file = ownedDirectory.appending(path: name.isEmpty || name == "." || name == ".." ? "download" : name)
        do {
            try data.write(to: file, options: .atomic)
            return .init(localURL: file, suggestedFileName: file.lastPathComponent)
        } catch {
            try? FileManager.default.removeItem(at: ownedDirectory)
            throw error
        }
    }

    public func discard(_ downloaded: AdministrativeDownloadedFile) throws {
        let file = downloaded.localURL.standardizedFileURL
        let ownedDirectory = file.deletingLastPathComponent()
        guard ownedDirectory.deletingLastPathComponent().path == directory.path,
            UUID(uuidString: ownedDirectory.lastPathComponent) != nil,
            ownedDirectory.resolvingSymlinksInPath().deletingLastPathComponent().path
                == directory.resolvingSymlinksInPath().path
        else { throw AdministrativeFileValidationError.escapingPath }
        guard FileManager.default.fileExists(atPath: ownedDirectory.path) else { return }
        try FileManager.default.removeItem(at: ownedDirectory)
    }
}
