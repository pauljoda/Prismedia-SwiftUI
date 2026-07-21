import Foundation

public protocol FileAdministrationServicing: Sendable {
    func roots() async throws -> [AdministrativeFileRoot]
    func children(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse
    func detail(rootID: UUID, path: String) async throws -> AdministrativeFileDetail
    func createFolder(rootID: UUID, parentPath: String, name: String) async throws -> AdministrativeFileOperationResponse
    func upload(item: AdministrativeFileUploadItem, rootID: UUID, targetPath: String) async throws
        -> AdministrativeFileOperationResponse
    func rename(rootID: UUID, path: String, name: String) async throws -> AdministrativeFileOperationResponse
    func move(sourceRootID: UUID, sourcePath: String, targetRootID: UUID, targetPath: String) async throws
        -> AdministrativeFileOperationResponse
    func delete(rootID: UUID, path: String) async throws -> AdministrativeFileOperationResponse
    func setExcluded(_ excluded: Bool, rootID: UUID, path: String) async throws
        -> AdministrativeFileOperationResponse
    func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse
    func prepareArchive(rootID: UUID, path: String) async throws -> AdministrativeFileArchivePreparation
    func archiveStatus(id: UUID) async throws -> AdministrativeFileArchivePreparation
    func downloadFile(rootID: UUID, path: String) async throws -> AdministrativeDownloadedFile
    func downloadArchive(_ preparation: AdministrativeFileArchivePreparation) async throws -> AdministrativeDownloadedFile
}
