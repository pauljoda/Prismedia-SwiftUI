import Foundation

public protocol RequestActivityServicing: Sendable {
    func listRequestActivityDownloads() async throws -> [RequestActivityDownload]
    func listRequestActivityWanted(
        _ list: RequestActivityWantedList,
        page: Int,
        pageSize: Int,
        kind: EntityKind?
    ) async throws -> RequestActivityWantedPage
    func listRequestActivityHistory(limit: Int?, entityID: UUID?) async throws -> [RequestActivityHistoryEntry]
    func fetchRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail
    func queueRequestActivityRelease(acquisitionID: UUID, candidateID: UUID) async throws
        -> RequestActivityAcquisitionDetail
    func blocklistRequestActivityCandidate(acquisitionID: UUID, candidateID: UUID) async throws
        -> RequestActivityAcquisitionDetail
    func researchRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail
    func retryRequestActivityImport(id: UUID, allowFormatChange: Bool) async throws -> RequestActivityAcquisitionDetail
    func cancelRequestActivityAcquisition(id: UUID) async throws -> RequestActivityAcquisitionDetail
    func uploadRequestActivityTorrent(_ upload: RequestActivityManualTorrentUpload) async throws
        -> RequestActivityAcquisitionDetail
    func removeRequestActivityAcquisition(id: UUID) async throws
    func fetchRequestActivityTransfer(id: UUID) async throws -> RequestActivityTransfer?
    func fetchRequestActivityFiles(id: UUID) async throws -> RequestActivityFiles
    func listRequestActivityBlocklist() async throws -> [RequestActivityBlocklistEntry]
    func removeRequestActivityBlocklistEntry(id: UUID) async throws
    func pauseMonitor(id: UUID) async throws
    func resumeMonitor(id: UUID) async throws
    func unmonitor(id: UUID) async throws -> EntityMonitorStopResponse
}
