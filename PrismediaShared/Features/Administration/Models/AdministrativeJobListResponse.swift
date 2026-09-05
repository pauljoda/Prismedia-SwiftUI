import Foundation

public struct AdministrativeJobListResponse: Decodable, Equatable, Sendable {
    public let items: [AdministrativeJobRun]
    public let counts: [AdministrativeJobCount]

    var activeCount: Int { count(statuses: Self.activeStatuses) }
    var queuedCount: Int { count(statuses: Self.queuedStatuses) }
    var failedCount: Int { count(statuses: Self.failedStatuses) }

    static let activeStatuses: Set<String> = ["active", PrismediaContractCodes.JobRunStatus.running]
    static let queuedStatuses: Set<String> = ["waiting", PrismediaContractCodes.JobRunStatus.queued, "delayed"]
    static let failedStatuses: Set<String> = [PrismediaContractCodes.JobRunStatus.failed]

    func count(type: String? = nil, statuses: Set<String>) -> Int {
        counts.filter { (type == nil || $0.type == type) && statuses.contains($0.status.lowercased()) }
            .reduce(0) { $0 + $1.count }
    }

    func jobs(statuses: Set<String>) -> [AdministrativeJobRun] {
        items.filter { statuses.contains($0.status.lowercased()) }
    }
}
