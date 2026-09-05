import SwiftUI

struct AdministrativeJobActivitySections: View {
    let snapshot: AdministrativeJobListResponse
    let isWorking: Bool
    let onCancel: (AdministrativeJobRun) -> Void

    var body: some View {
        if snapshot.activeCount > 0 {
            activity(
                snapshot.jobs(statuses: AdministrativeJobListResponse.activeStatuses),
                title: "Running Now", count: snapshot.activeCount, status: "running", expanded: true)
        }
        if snapshot.queuedCount > 0 {
            activity(
                snapshot.jobs(statuses: AdministrativeJobListResponse.queuedStatuses),
                title: "Queued", count: snapshot.queuedCount, status: "queued", expanded: false)
        }
        if snapshot.failedCount > 0 {
            activity(
                snapshot.jobs(statuses: AdministrativeJobListResponse.failedStatuses),
                title: "Needs Attention", count: snapshot.failedCount, status: "failed", expanded: false)
        }
    }

    private func activity(
        _ jobs: [AdministrativeJobRun], title: String, count: Int,
        status: String, expanded: Bool
    ) -> some View {
        Section(title) {
            if jobs.isEmpty {
                Text("\(count) \(status) jobs not included in recent activity.")
                    .foregroundStyle(PrismediaColor.textSecondary)
            }
            ForEach(grouped(jobs), id: \.type) { group in
                AdministrativeJobGroupView(
                    title: group.type.replacingOccurrences(of: "-", with: " ").capitalized,
                    jobs: group.jobs, statusLabel: status, isWorking: isWorking,
                    initiallyExpanded: expanded, onCancel: onCancel)
            }
        }
    }

    private func grouped(_ jobs: [AdministrativeJobRun]) -> [(type: String, jobs: [AdministrativeJobRun])] {
        Dictionary(grouping: jobs, by: \.type)
            .map { (type: $0.key, jobs: $0.value) }
            .sorted { $0.type.localizedStandardCompare($1.type) == .orderedAscending }
    }
}
