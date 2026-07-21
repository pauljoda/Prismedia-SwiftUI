import Foundation

@MainActor
public struct FileArchiveDownloadUseCase {
    private let service: any FileAdministrationServicing

    public init(service: any FileAdministrationServicing) { self.service = service }

    public func prepareAndDownload(
        rootID: UUID,
        path: String,
        progress: @MainActor @Sendable (AdministrativeFileArchivePreparation) -> Void
    ) async throws -> AdministrativeDownloadedFile {
        var preparation = try await service.prepareArchive(rootID: rootID, path: path)
        progress(preparation)
        while !preparation.ready, preparation.error == nil {
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(500))
            preparation = try await service.archiveStatus(id: preparation.id)
            progress(preparation)
        }
        if let error = preparation.error { throw AdministrativeFileArchiveError.failed(error) }
        try Task.checkCancellation()
        return try await service.downloadArchive(preparation)
    }
}
