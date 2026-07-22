import Foundation

extension PrismediaAPIClient {
    public func listRequestActivityDownloads() async throws -> [RequestActivityDownload] {
        try await send([RequestActivityDownload].self, path: "/api/acquisitions/downloads")
    }

    public func listRequestActivityWanted(
        _ list: RequestActivityWantedList,
        page: Int = 1,
        pageSize: Int = 50,
        kind: EntityKind? = nil
    ) async throws -> RequestActivityWantedPage {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            requestActivityNsfwVisibilityQueryItem,
        ]
        if let kind {
            queryItems.append(URLQueryItem(name: "kind", value: kind.rawValue))
        }
        return try await send(RequestActivityWantedPage.self, path: list.path, queryItems: queryItems)
    }

    public func listRequestActivityHistory(
        limit: Int? = nil,
        entityID: UUID? = nil
    ) async throws -> [RequestActivityHistoryEntry] {
        var queryItems: [URLQueryItem] = []
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let entityID {
            queryItems.append(URLQueryItem(name: "entityId", value: entityID.uuidString.lowercased()))
        }
        return try await send(
            [RequestActivityHistoryEntry].self,
            path: "/api/acquisitions/history",
            queryItems: queryItems
        )
    }

    public func fetchRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail {
        try await send(RequestActivityAcquisitionDetail.self, path: requestActivityAcquisitionPath(id))
    }

    /// The latest acquisition backing a library entity, or `nil` when it has none
    /// (the common case for scanned-in items).
    public func fetchRequestActivityAcquisition(
        forEntity entityID: UUID
    ) async throws -> RequestActivityAcquisitionDetail? {
        do {
            return try await send(
                RequestActivityAcquisitionDetail.self,
                path: "/api/acquisitions/for-entity/\(entityID.uuidString.lowercased())"
            )
        } catch PrismediaAPIError.httpStatus(404, _) {
            return nil
        }
    }

    /// Requests an existing library entity by id — a wanted placeholder's "Search for release".
    /// The server resolves the entity's kind and provider identity itself and starts the
    /// auto-grabbing, monitored acquisition.
    public func commitEntityRequest(entityID: UUID) async throws {
        try await sendExpectingNoContent(
            path: "/api/requests/commit-entity",
            method: "POST",
            queryItems: [URLQueryItem(name: "entityId", value: entityID.uuidString.lowercased())]
        )
    }

    public func queueRequestActivityRelease(
        acquisitionID: UUID,
        candidateID: UUID
    ) async throws -> RequestActivityAcquisitionDetail {
        try await send(
            RequestActivityAcquisitionDetail.self,
            path: "\(requestActivityAcquisitionPath(acquisitionID))/queue",
            method: "POST",
            body: RequestActivityQueueReleaseRequest(candidateId: candidateID)
        )
    }

    public func blocklistRequestActivityCandidate(
        acquisitionID: UUID,
        candidateID: UUID
    ) async throws -> RequestActivityAcquisitionDetail {
        try await send(
            RequestActivityAcquisitionDetail.self,
            path:
                "\(requestActivityAcquisitionPath(acquisitionID))/candidates/\(candidateID.uuidString.lowercased())/blocklist",
            method: "POST"
        )
    }

    public func researchRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail {
        try await send(
            RequestActivityAcquisitionDetail.self,
            path: "\(requestActivityAcquisitionPath(id))/search",
            method: "POST"
        )
    }

    public func retryRequestActivityImport(
        id: UUID,
        allowFormatChange: Bool
    ) async throws -> RequestActivityAcquisitionDetail {
        try await send(
            RequestActivityAcquisitionDetail.self,
            path: "\(requestActivityAcquisitionPath(id))/import",
            method: "POST",
            body: RequestActivityRetryImportRequest(allowFormatChange: allowFormatChange)
        )
    }

    public func cancelRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail {
        try await send(
            RequestActivityAcquisitionDetail.self,
            path: "\(requestActivityAcquisitionPath(id))/cancel",
            method: "POST"
        )
    }

    public func uploadRequestActivityTorrent(
        _ upload: RequestActivityManualTorrentUpload
    ) async throws -> RequestActivityAcquisitionDetail {
        try await sendMultipart(
            RequestActivityAcquisitionDetail.self,
            path: "\(requestActivityAcquisitionPath(upload.acquisitionID))/upload-torrent",
            fieldName: "file",
            fileName: upload.fileName,
            contentType: "application/x-bittorrent",
            data: upload.data
        )
    }

    public func uploadRequestActivityContent(
        _ upload: RequestActivityManualContentUpload,
        progress: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> RequestActivityAcquisitionDetail {
        try await sendMultipartFiles(
            RequestActivityAcquisitionDetail.self,
            path: "/api/acquisitions/for-entity/\(upload.entityID.uuidString.lowercased())/upload",
            files: upload.files.map { file in
                HTTPMultipartUploadFile(
                    fieldName: "files",
                    fileName: file.fileName,
                    contentType: file.contentType,
                    sourceURL: file.url,
                    sizeBytes: file.sizeBytes,
                    relativePathFieldName: "relativePaths",
                    relativePath: file.relativePath
                )
            },
            progress: { value in
                Task { @MainActor in progress(value) }
            }
        )
    }

    public func removeRequestActivityAcquisition(id: UUID) async throws {
        try await sendExpectingNoContent(path: requestActivityAcquisitionPath(id), method: "DELETE")
    }

    public func fetchRequestActivityTransfer(id: UUID) async throws -> RequestActivityTransfer? {
        let data = try await mediaData(for: "\(requestActivityAcquisitionPath(id))/transfer")
        guard !data.isEmpty else { return nil }
        do {
            return try PrismediaJSON.decoder().decode(RequestActivityTransfer.self, from: data)
        } catch {
            throw PrismediaAPIError.decoding(error)
        }
    }

    public func fetchRequestActivityFiles(id: UUID) async throws -> RequestActivityFiles {
        try await send(RequestActivityFiles.self, path: "\(requestActivityAcquisitionPath(id))/files")
    }

    public func listRequestActivityBlocklist() async throws -> [RequestActivityBlocklistEntry] {
        try await send([RequestActivityBlocklistEntry].self, path: "/api/acquisitions/blocklist")
    }

    public func removeRequestActivityBlocklistEntry(id: UUID) async throws {
        try await sendExpectingNoContent(
            path: "/api/acquisitions/blocklist/\(id.uuidString.lowercased())",
            method: "DELETE"
        )
    }

    private var requestActivityNsfwVisibilityQueryItem: URLQueryItem {
        URLQueryItem(name: "hideNsfw", value: allowsNsfwContent ? "false" : "true")
    }

    private func requestActivityAcquisitionPath(_ id: UUID) -> String {
        "/api/acquisitions/\(id.uuidString.lowercased())"
    }
}

extension PrismediaAPIClient: RequestActivityServicing {}
