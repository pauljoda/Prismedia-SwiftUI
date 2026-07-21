import Foundation

#if DEBUG
    struct Step4AdministrationPreviewService: FileAdministrationServicing, PluginAdministrationServicing {
        static let rootID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        func roots() async throws -> [AdministrativeFileRoot] {
            [AdministrativeFileRoot(id: Self.rootID, label: "Movies", path: "/media/movies", enabled: true)]
        }

        func children(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse {
            AdministrativeFileChildrenResponse(
                rootID: rootID,
                path: path,
                entries: path.isEmpty
                    ? [
                        AdministrativeFileEntry(
                            rootID: rootID, path: "Arrival", name: "Arrival", kind: "directory",
                            sizeBytes: nil, mimeType: nil, modifiedAt: Date(timeIntervalSince1970: 1_720_000_000),
                            excluded: false
                        ),
                        AdministrativeFileEntry(
                            rootID: rootID, path: "Skip.mkv", name: "Skip.mkv", kind: "file",
                            sizeBytes: 734_003_200, mimeType: "video/x-matroska",
                            modifiedAt: Date(timeIntervalSince1970: 1_720_000_000), excluded: true
                        ),
                    ]
                    : [
                        AdministrativeFileEntry(
                            rootID: rootID, path: "Arrival/Arrival.mkv", name: "Arrival.mkv", kind: "file",
                            sizeBytes: 8_589_934_592, mimeType: "video/x-matroska",
                            modifiedAt: Date(timeIntervalSince1970: 1_720_000_000), excluded: false
                        )
                    ]
            )
        }

        func detail(rootID: UUID, path: String) async throws -> AdministrativeFileDetail {
            let entry =
                try await children(rootID: rootID, path: "").entries.first { $0.path == path }
                ?? AdministrativeFileEntry(
                    rootID: rootID, path: path, name: URL(fileURLWithPath: path).lastPathComponent,
                    kind: path.hasSuffix(".mkv") ? "file" : "directory", sizeBytes: 8_589_934_592,
                    mimeType: "video/x-matroska", modifiedAt: Date(timeIntervalSince1970: 1_720_000_000),
                    excluded: false
                )
            return AdministrativeFileDetail(
                entry: entry,
                absolutePath: "/media/movies/\(path)",
                createdAt: Date(timeIntervalSince1970: 1_710_000_000),
                linkedEntities: [],
                canPreview: !entry.isDirectory,
                directoryFileCount: entry.isDirectory ? 1 : nil,
                directoryTotalSizeBytes: entry.isDirectory ? 8_589_934_592 : nil
            )
        }

        func createFolder(rootID: UUID, parentPath: String, name: String) async throws
            -> AdministrativeFileOperationResponse
        { .init(scansQueued: 1) }
        func upload(item: AdministrativeFileUploadItem, rootID: UUID, targetPath: String) async throws
            -> AdministrativeFileOperationResponse
        { .init(scansQueued: 1) }
        func rename(rootID: UUID, path: String, name: String) async throws
            -> AdministrativeFileOperationResponse
        { .init(scansQueued: 1) }
        func move(sourceRootID: UUID, sourcePath: String, targetRootID: UUID, targetPath: String) async throws
            -> AdministrativeFileOperationResponse
        { .init(scansQueued: 1) }
        func delete(rootID: UUID, path: String) async throws -> AdministrativeFileOperationResponse {
            .init(scansQueued: 1)
        }
        func setExcluded(_ excluded: Bool, rootID: UUID, path: String) async throws
            -> AdministrativeFileOperationResponse
        { .init(scansQueued: 1) }
        func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse {
            .init(scansQueued: 1)
        }
        func prepareArchive(rootID: UUID, path: String) async throws -> AdministrativeFileArchivePreparation {
            .init(
                id: UUID(), fileName: "Movies.zip", ready: false, progressPercent: 45, processedFiles: 9,
                totalFiles: 20, error: nil)
        }
        func archiveStatus(id: UUID) async throws -> AdministrativeFileArchivePreparation {
            .init(
                id: id, fileName: "Movies.zip", ready: true, progressPercent: 100, processedFiles: 20, totalFiles: 20,
                error: nil)
        }
        func downloadFile(rootID: UUID, path: String) async throws -> AdministrativeDownloadedFile {
            throw CancellationError()
        }
        func downloadArchive(_ preparation: AdministrativeFileArchivePreparation) async throws
            -> AdministrativeDownloadedFile
        {
            throw CancellationError()
        }

        func catalog() async throws -> [AdministrativePlugin] {
            [
                AdministrativePlugin(
                    id: "tmdb", name: "TMDB", version: "1.1.0", installed: true, enabled: true, isNsfw: false,
                    supports: [.init(entityKind: "movie", actions: ["search", "lookup-id"])],
                    auth: [.init(key: "api_key", label: "API Key", required: true, url: "https://example.invalid")],
                    missingAuthKeys: [], updateAvailable: true, availableVersion: "1.2.0"
                ),
                AdministrativePlugin(
                    id: "open-library", name: "Open Library", version: "2.0.0", installed: false,
                    enabled: false, isNsfw: false,
                    supports: [.init(entityKind: "book", actions: ["search"])], missingAuthKeys: [],
                    updateAvailable: false, availableVersion: nil
                ),
                AdministrativePlugin(
                    id: "stash-box", name: "Stash Box", version: "1.0.0", installed: true, enabled: true,
                    isNsfw: true, supports: [.init(entityKind: "video", actions: ["search"])],
                    auth: [.init(key: "api_key", label: "API Key", required: true, url: nil)],
                    missingAuthKeys: ["api_key"], updateAvailable: false, availableVersion: nil
                ),
            ]
        }
        func stashCatalog() async throws -> [AdministrativeStashScraper] {
            [.init(providerID: "stash-community-film", name: "Community Film", version: "2026.07")]
        }
        func install(id: String) async throws -> AdministrativePlugin { try await catalog().first { $0.id == id }! }
        func update(id: String) async throws -> AdministrativePlugin { try await install(id: id) }
        func remove(id: String) async throws {}
        func saveAuth(id: String, values: [String: String?]) async throws {}
    }
#endif
