import Foundation

public struct FileAdministrationService: FileAdministrationServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func roots() async throws -> [AdministrativeFileRoot] {
        try await client.listAdministrativeFileRoots()
    }

    public func children(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse {
        let path = try AdministrativeFilePathPolicy.validatedRelativePath(path, allowsEmpty: true)
        return try await client.listAdministrativeFileChildren(rootID: rootID, path: path)
    }

    public func detail(rootID: UUID, path: String) async throws -> AdministrativeFileDetail {
        let path = try AdministrativeFilePathPolicy.validatedRelativePath(path, allowsEmpty: true)
        return try await client.administrativeFileDetail(rootID: rootID, path: path)
    }

    public func createFolder(rootID: UUID, parentPath: String, name: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try await client.createAdministrativeFileFolder(
            rootID: rootID,
            parentPath: try AdministrativeFilePathPolicy.validatedRelativePath(parentPath, allowsEmpty: true),
            name: try AdministrativeFilePathPolicy.validatedName(name)
        )
    }

    public func upload(item: AdministrativeFileUploadItem, rootID: UUID, targetPath: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try Task.checkCancellation()
        let scoped = item.securityScopeURL?.startAccessingSecurityScopedResource() ?? false
        defer { if scoped { item.securityScopeURL?.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: item.localURL, options: .mappedIfSafe)
        try Task.checkCancellation()
        return try await client.uploadAdministrativeFile(
            rootID: rootID,
            targetPath: try AdministrativeFilePathPolicy.validatedRelativePath(targetPath, allowsEmpty: true),
            relativePath: try AdministrativeFilePathPolicy.validatedRelativePath(item.relativePath),
            fileName: item.localURL.lastPathComponent,
            data: data
        )
    }

    public func rename(rootID: UUID, path: String, name: String) async throws -> AdministrativeFileOperationResponse {
        try await client.renameAdministrativeFile(
            rootID: rootID,
            path: try AdministrativeFilePathPolicy.validatedRelativePath(path),
            name: try AdministrativeFilePathPolicy.validatedName(name)
        )
    }

    public func move(sourceRootID: UUID, sourcePath: String, targetRootID: UUID, targetPath: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try AdministrativeFilePathPolicy.validateMove(
            sourcePath: sourcePath,
            targetPath: targetPath,
            sameRoot: sourceRootID == targetRootID
        )
        return try await client.moveAdministrativeFile(
            sourceRootID: sourceRootID,
            sourcePath: try AdministrativeFilePathPolicy.validatedRelativePath(sourcePath),
            targetRootID: targetRootID,
            targetPath: try AdministrativeFilePathPolicy.validatedRelativePath(targetPath)
        )
    }

    public func delete(rootID: UUID, path: String) async throws -> AdministrativeFileOperationResponse {
        try await client.deleteAdministrativeFile(
            rootID: rootID,
            path: try AdministrativeFilePathPolicy.validatedRelativePath(path)
        )
    }

    public func setExcluded(_ excluded: Bool, rootID: UUID, path: String) async throws
        -> AdministrativeFileOperationResponse
    {
        let path = try AdministrativeFilePathPolicy.validatedRelativePath(path)
        return try await excluded
            ? client.excludeAdministrativeFile(rootID: rootID, path: path)
            : client.removeAdministrativeFileExclusion(rootID: rootID, path: path)
    }

    public func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse {
        let path = try path.map { try AdministrativeFilePathPolicy.validatedRelativePath($0, allowsEmpty: true) }
        return try await client.rescanAdministrativeFiles(rootID: rootID, path: path)
    }

    public func prepareArchive(rootID: UUID, path: String) async throws -> AdministrativeFileArchivePreparation {
        try await client.prepareAdministrativeFileArchive(
            rootID: rootID,
            path: try AdministrativeFilePathPolicy.validatedRelativePath(path, allowsEmpty: true)
        )
    }

    public func archiveStatus(id: UUID) async throws -> AdministrativeFileArchivePreparation {
        try await client.administrativeFileArchiveStatus(id: id)
    }

    public func downloadFile(rootID: UUID, path: String) async throws -> AdministrativeDownloadedFile {
        let path = try AdministrativeFilePathPolicy.validatedRelativePath(path)
        let data = try await client.downloadAdministrativeFile(rootID: rootID, path: path)
        let name = URL(fileURLWithPath: path).lastPathComponent
        return try storeDownload(data: data, suggestedName: name)
    }

    public func downloadArchive(_ preparation: AdministrativeFileArchivePreparation) async throws
        -> AdministrativeDownloadedFile
    {
        guard preparation.ready, preparation.error == nil else { throw AdministrativeFileArchiveError.notReady }
        let data = try await client.downloadAdministrativeFileArchive(id: preparation.id)
        return try storeDownload(data: data, suggestedName: preparation.fileName)
    }

    private func storeDownload(data: Data, suggestedName: String) throws -> AdministrativeDownloadedFile {
        let safeName = suggestedName.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\\", with: "_")
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "PrismediaDownloads", directoryHint: .isDirectory)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: safeName.isEmpty ? "download" : safeName)
        try data.write(to: url, options: .atomic)
        return AdministrativeDownloadedFile(localURL: url, suggestedFileName: url.lastPathComponent)
    }
}
