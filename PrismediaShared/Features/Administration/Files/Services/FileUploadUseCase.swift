import Foundation

@MainActor
public struct FileUploadUseCase {
    private let service: any FileTransferServicing

    public init(service: any FileTransferServicing) { self.service = service }

    public func upload(
        _ items: [AdministrativeFileUploadItem],
        rootID: UUID,
        targetPath: String,
        progress: @MainActor @Sendable (AdministrativeFileUploadProgress) -> Void
    ) async -> AdministrativeFileUploadResult {
        var successful: [String] = []
        var failures: [AdministrativeFileUploadFailure] = []
        var scansQueued = 0
        var isCancelled = false
        progress(.init(completed: 0, total: items.count, currentPath: items.first?.relativePath))
        for (index, item) in items.enumerated() {
            if Task.isCancelled {
                isCancelled = true
                break
            }
            do {
                let result = try await service.upload(item: item, rootID: rootID, targetPath: targetPath)
                successful.append(item.relativePath)
                scansQueued = max(scansQueued, result.scansQueued)
            } catch is CancellationError {
                isCancelled = true
                break
            } catch {
                if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                    isCancelled = true
                    break
                }
                failures.append(.init(relativePath: item.relativePath, message: error.localizedDescription))
            }
            progress(
                .init(
                    completed: index + 1,
                    total: items.count,
                    currentPath: index + 1 < items.count ? items[index + 1].relativePath : nil
                ))
        }
        return .init(
            successfulPaths: successful, failures: failures, scansQueued: scansQueued, isCancelled: isCancelled)
    }
}
