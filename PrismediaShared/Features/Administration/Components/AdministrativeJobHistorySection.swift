import SwiftUI

struct AdministrativeJobHistorySection: View {
    let snapshot: AdministrativeJobListResponse

    var body: some View {
        let completed = snapshot.jobs(statuses: [PrismediaContractCodes.JobRunStatus.completed])
        if !completed.isEmpty {
            Section("Recently Completed") {
                let groups = Dictionary(grouping: completed, by: \.type)
                ForEach(groups.keys.sorted(), id: \.self) { type in
                    AdministrativeJobGroupView(
                        title: type.replacingOccurrences(of: "-", with: " ").capitalized,
                        jobs: groups[type] ?? [], statusLabel: "completed", isWorking: false,
                        initiallyExpanded: false, onCancel: { _ in })
                }
            }
        }
    }
}
