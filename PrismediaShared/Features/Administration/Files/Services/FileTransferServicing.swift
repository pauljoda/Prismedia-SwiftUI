import Foundation

/// Transfers library files and owns the temporary copies prepared for export.
public protocol FileTransferServicing: Sendable {
    func upload(item: AdministrativeFileUploadItem, rootID: UUID, targetPath: String) async throws
        -> AdministrativeFileOperationResponse
    func prepareArchive(rootID: UUID, path: String) async throws -> AdministrativeFileArchivePreparation
    func archiveStatus(id: UUID) async throws -> AdministrativeFileArchivePreparation
    func downloadFile(rootID: UUID, path: String) async throws -> AdministrativeDownloadedFile
    func downloadArchive(_ preparation: AdministrativeFileArchivePreparation) async throws
        -> AdministrativeDownloadedFile
    /// Releases only the temporary copy belonging to this download, never its server source.
    func discardDownload(_ downloaded: AdministrativeDownloadedFile) async throws
}
