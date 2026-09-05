import SwiftUI

struct AdministrativeJobStatusSection: View {
    let snapshot: AdministrativeJobListResponse

    var body: some View {
        Section("Worker Activity") {
            LabeledContent {
                Text(snapshot.activeCount, format: .number).monospacedDigit()
            } label: {
                Label("Running", systemImage: "arrow.triangle.2.circlepath")
            }
            LabeledContent {
                Text(snapshot.queuedCount, format: .number).monospacedDigit()
            } label: {
                Label("Queued", systemImage: "clock")
            }
            LabeledContent {
                Text(snapshot.failedCount, format: .number).monospacedDigit()
            } label: {
                Label("Failed", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(snapshot.failedCount > 0 ? PrismediaColor.destructive : PrismediaColor.textPrimary)
            }
        }
    }
}
