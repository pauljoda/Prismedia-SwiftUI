import Foundation

public protocol FileAdministrationServicing: FileTransferServicing {
    func roots() async throws -> [AdministrativeFileRoot]
    func children(rootID: UUID, path: String) async throws -> AdministrativeFileChildrenResponse
    func detail(rootID: UUID, path: String) async throws -> AdministrativeFileDetail
    func createFolder(rootID: UUID, parentPath: String, name: String) async throws
        -> AdministrativeFileOperationResponse
    func rename(rootID: UUID, path: String, name: String) async throws -> AdministrativeFileOperationResponse
    func move(sourceRootID: UUID, sourcePath: String, targetRootID: UUID, targetPath: String) async throws
        -> AdministrativeFileOperationResponse
    func delete(rootID: UUID, path: String) async throws -> AdministrativeFileOperationResponse
    func setExcluded(_ excluded: Bool, rootID: UUID, path: String) async throws
        -> AdministrativeFileOperationResponse
    func rescan(rootID: UUID, path: String?) async throws -> AdministrativeFileOperationResponse
}
