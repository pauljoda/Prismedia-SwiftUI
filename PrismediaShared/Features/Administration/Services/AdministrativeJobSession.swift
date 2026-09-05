import Foundation
import Observation

/// Preserves server-confirmed activity and keeps command outcomes separate from polling failures.
@Observable @MainActor
final class AdministrativeJobSession {
    private(set) var snapshot = AdministrativeJobListResponse(items: [], counts: [])
    private(set) var hasLoaded = false
    private(set) var isMutating = false
    private(set) var refreshError: String?
    var actionError: String?
    var notice: String?

    private var readID: UUID?
    private let service: any AdministrativeJobServicing

    var isRefreshing: Bool { readID != nil }

    init(service: any AdministrativeJobServicing) { self.service = service }

    func refresh() async {
        guard !isRefreshing, !isMutating, !Task.isCancelled else { return }
        await readSnapshot()
    }

    func perform(_ command: AdministrativeJobCommand) async {
        guard !isMutating, !Task.isCancelled else { return }
        isMutating = true
        // A poll started before this command must not replace its newer result.
        readID = nil
        actionError = nil
        notice = nil
        defer { isMutating = false }
        do {
            switch command {
            case .run(let type):
                _ = try await service.createJob(type: type)
                notice = "Job queued."
            case .cancel(let id):
                let count = try await service.cancelJob(id: id)
                notice = count == 0 ? "This job is no longer running or queued." : "Job stopped."
            case .stop(let type):
                let count = try await service.cancelJobs(type: type)
                notice = "Stopped \(count) job\(count == 1 ? "" : "s")."
            case .clearFailures(let type):
                let count = try await service.clearFailures(type: type)
                notice = "Cleared \(count) failed job\(count == 1 ? "" : "s")."
            }
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            actionError = error.localizedDescription
            return
        }
        await readSnapshot()
    }

    private func readSnapshot() async {
        let requestID = UUID()
        readID = requestID
        defer { if readID == requestID { readID = nil } }
        do {
            let latest = try await service.jobs()
            guard readID == requestID, !Task.isCancelled else { return }
            snapshot = latest
            hasLoaded = true
            refreshError = nil
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            guard readID == requestID, !Task.isCancelled else { return }
            refreshError = error.localizedDescription
        }
    }
}
