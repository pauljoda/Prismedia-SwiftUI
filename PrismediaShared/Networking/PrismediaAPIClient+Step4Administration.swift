import Foundation

extension PrismediaAPIClient {
    public func administrativeFileDetail(rootID: UUID, path: String) async throws -> AdministrativeFileDetail {
        try await send(
            AdministrativeFileDetail.self,
            path: "/api/files/detail",
            queryItems: fileVisibilityItems(rootID: rootID, path: path)
        )
    }

    public func createAdministrativeFileFolder(rootID: UUID, parentPath: String, name: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try await send(
            AdministrativeFileOperationResponse.self,
            path: "/api/files/folders",
            method: "POST",
            queryItems: [administrativeFilesVisibilityQueryItem],
            body: AdministrativeFileCreateFolderRequest(rootID: rootID, parentPath: parentPath, name: name)
        )
    }

    public func renameAdministrativeFile(rootID: UUID, path: String, name: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try await send(
            AdministrativeFileOperationResponse.self,
            path: "/api/files/rename",
            method: "PATCH",
            queryItems: [administrativeFilesVisibilityQueryItem],
            body: AdministrativeFileRenameRequest(rootID: rootID, path: path, name: name)
        )
    }

    public func moveAdministrativeFile(
        sourceRootID: UUID,
        sourcePath: String,
        targetRootID: UUID,
        targetPath: String
    ) async throws -> AdministrativeFileOperationResponse {
        try await send(
            AdministrativeFileOperationResponse.self,
            path: "/api/files/move",
            method: "POST",
            queryItems: [administrativeFilesVisibilityQueryItem],
            body: AdministrativeFileMoveRequest(
                sourceRootID: sourceRootID,
                sourcePath: sourcePath,
                targetRootID: targetRootID,
                targetPath: targetPath
            )
        )
    }

    public func deleteAdministrativeFile(rootID: UUID, path: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try await send(
            AdministrativeFileOperationResponse.self,
            path: "/api/files",
            method: "DELETE",
            queryItems: fileVisibilityItems(rootID: rootID, path: path)
        )
    }

    public func excludeAdministrativeFile(rootID: UUID, path: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try await send(
            AdministrativeFileOperationResponse.self,
            path: "/api/files/exclusions",
            method: "POST",
            queryItems: [administrativeFilesVisibilityQueryItem],
            body: AdministrativeFileExclusionRequest(rootID: rootID, path: path)
        )
    }

    public func removeAdministrativeFileExclusion(rootID: UUID, path: String) async throws
        -> AdministrativeFileOperationResponse
    {
        try await send(
            AdministrativeFileOperationResponse.self,
            path: "/api/files/exclusions",
            method: "DELETE",
            queryItems: fileVisibilityItems(rootID: rootID, path: path)
        )
    }

    public func prepareAdministrativeFileArchive(rootID: UUID, path: String) async throws
        -> AdministrativeFileArchivePreparation
    {
        try await send(
            AdministrativeFileArchivePreparation.self,
            path: "/api/files/archives",
            method: "POST",
            queryItems: [administrativeFilesVisibilityQueryItem],
            body: AdministrativeFileArchiveRequest(rootID: rootID, path: path)
        )
    }

    public func administrativeFileArchiveStatus(id: UUID) async throws -> AdministrativeFileArchivePreparation {
        try await send(
            AdministrativeFileArchivePreparation.self,
            path: "/api/files/archives/\(id.uuidString.lowercased())"
        )
    }

    public func uploadAdministrativeFile(
        rootID: UUID,
        targetPath: String,
        relativePath: String,
        fileName: String,
        data: Data
    ) async throws -> AdministrativeFileOperationResponse {
        let boundary = "PrismediaFiles-\(UUID().uuidString)"
        var body = Data()
        appendMultipartField("rootId", value: rootID.uuidString.lowercased(), boundary: boundary, to: &body)
        appendMultipartField("targetPath", value: targetPath, boundary: boundary, to: &body)
        appendMultipartField("relativePaths", value: relativePath, boundary: boundary, to: &body)
        appendMultipartFile(fileName: fileName, data: data, boundary: boundary, to: &body)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        var request = URLRequest(url: try url(path: "/api/files/upload"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        if let accessToken { request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") }
        let response = try await sendRawRequest(request)
        return try PrismediaJSON.decoder().decode(AdministrativeFileOperationResponse.self, from: response)
    }

    public func downloadAdministrativeFile(rootID: UUID, path: String) async throws -> Data {
        try await authenticatedAdministrativeDownload(
            path: "/api/files/download",
            queryItems: fileVisibilityItems(rootID: rootID, path: path)
        )
    }

    public func downloadAdministrativeFileArchive(id: UUID) async throws -> Data {
        try await authenticatedAdministrativeDownload(
            path: "/api/files/archives/\(id.uuidString.lowercased())/content",
            queryItems: []
        )
    }

    public func listAdministrativePluginCatalog() async throws -> [AdministrativePlugin] {
        try await send([AdministrativePlugin].self, path: "/api/plugins")
    }

    public func listAdministrativeStashScrapers() async throws -> [AdministrativeStashScraper] {
        try await send([AdministrativeStashScraper].self, path: "/api/plugins/stash-scrapers")
    }

    public func installAdministrativePlugin(id: String) async throws -> AdministrativePlugin {
        try await send(AdministrativePlugin.self, path: pluginPath(id), method: "POST")
    }

    public func removeAdministrativePlugin(id: String) async throws {
        try await sendExpectingNoContent(path: pluginPath(id), method: "DELETE")
    }

    public func saveAdministrativePluginAuth(id: String, values: [String: String?]) async throws {
        try await sendExpectingNoContent(
            path: "\(pluginPath(id))/auth",
            method: "PUT",
            body: AdministrativePluginAuthUpdateRequest(values: values)
        )
    }

    private var administrativeFilesVisibilityQueryItem: URLQueryItem {
        URLQueryItem(name: "hideNsfw", value: allowsNsfwContent ? "false" : "true")
    }

    private func fileVisibilityItems(rootID: UUID, path: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "rootId", value: rootID.uuidString.lowercased()),
            URLQueryItem(name: "path", value: path),
            administrativeFilesVisibilityQueryItem,
        ]
    }

    private func pluginPath(_ id: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/?#")
        let encoded = id.addingPercentEncoding(withAllowedCharacters: allowed) ?? id
        return "/api/plugins/\(encoded)"
    }

    private func authenticatedAdministrativeDownload(path: String, queryItems: [URLQueryItem]) async throws -> Data {
        var request = URLRequest(url: try url(path: path, queryItems: queryItems))
        request.httpMethod = "GET"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        if let accessToken { request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") }
        return try await sendRawRequest(request)
    }

    private func appendMultipartField(_ name: String, value: String, boundary: String, to body: inout Data) {
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
        body.append(Data(value.utf8))
        body.append(Data("\r\n".utf8))
    }

    private func appendMultipartFile(fileName: String, data: Data, boundary: String, to body: inout Data) {
        let safeName = fileName.replacingOccurrences(of: "\"", with: "_").replacingOccurrences(of: "\r", with: "_")
            .replacingOccurrences(of: "\n", with: "_")
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"files\"; filename=\"\(safeName)\"\r\n".utf8))
        body.append(Data("Content-Type: application/octet-stream\r\n\r\n".utf8))
        body.append(data)
    }
}
