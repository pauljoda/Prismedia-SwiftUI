import Foundation

public protocol EntityAcquisitionServicing: Sendable {
    func loadState(entityID: UUID) async throws -> EntityMonitorState
    func latestAcquisition(entityID: UUID) async throws -> RequestActivityAcquisitionDetail?
    func startMonitor(entityID: UUID) async throws
    func pauseMonitor(id: UUID) async throws
    func resumeMonitor(id: UUID) async throws
    func searchAgain(acquisitionID: UUID) async throws
    func searchForRelease(entityID: UUID) async throws
    func unmonitor(id: UUID) async throws -> Bool
}
