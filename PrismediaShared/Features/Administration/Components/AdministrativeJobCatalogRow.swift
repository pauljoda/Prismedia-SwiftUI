import SwiftUI

struct AdministrativeJobCatalogRow: View {
    let title: String
    let description: String
    let systemImage: String
    let activeCount: Int
    let queuedCount: Int
    let failedCount: Int
    let isWorking: Bool
    let onRun: () -> Void
    let onStop: () -> Void
    let onClearFailures: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: PrismediaSpacing.medium) {
            Label {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(title)
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            } icon: {
                Image(systemName: systemImage)
            }

            Spacer(minLength: PrismediaSpacing.small)

            if activeCount + queuedCount > 0 {
                Button("Stop", systemImage: "stop.fill", role: .destructive, action: onStop)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Stop \(title)")
            } else {
                Button("Run", systemImage: "play.fill", action: onRun)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Run \(title)")
            }

            if failedCount > 0 {
                Button("Clear Failures", systemImage: "xmark.circle", action: onClearFailures)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Clear \(title) failures")
            }
        }
        .disabled(isWorking)
    }

    private var statusDescription: String {
        var parts: [String] = []
        if activeCount > 0 { parts.append("\(activeCount) running") }
        if queuedCount > 0 { parts.append("\(queuedCount) queued") }
        if failedCount > 0 { parts.append("\(failedCount) failed") }
        return parts.isEmpty ? description : parts.joined(separator: " · ")
    }
}

#if DEBUG
    #Preview("Job Catalog Row") {
        List {
            AdministrativeJobCatalogRow(
                title: "Videos",
                description: "Walk library roots for new video files.",
                systemImage: "folder.badge.magnifyingglass",
                activeCount: 1,
                queuedCount: 12,
                failedCount: 0,
                isWorking: false,
                onRun: {},
                onStop: {},
                onClearFailures: {}
            )
        }
    }
#endif
