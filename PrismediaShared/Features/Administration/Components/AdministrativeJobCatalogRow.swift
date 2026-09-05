import SwiftUI

struct AdministrativeJobCatalogRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let description: String
    let systemImage: String
    let activeCount: Int
    let queuedCount: Int
    let failedCount: Int
    let isWorking: Bool
    let accent: Color
    var actionTitle = "Run"
    let onRun: () -> Void
    let onStop: () -> Void
    let onClearFailures: () -> Void

    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PrismediaSpacing.medium))
            : AnyLayout(HStackLayout(alignment: .center, spacing: PrismediaSpacing.medium))
        layout {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Label {
                    Text(title).font(.headline)
                } icon: {
                    Image(systemName: systemImage).foregroundStyle(accent)
                }
                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: PrismediaSpacing.small) {
                if activeCount + queuedCount > 0 {
                    PrismediaButton("Stop", variant: .destructive, action: onStop)
                        .accessibilityLabel("Stop \(title)")
                } else {
                    PrismediaButton(actionTitle, action: onRun)
                        .accessibilityLabel("\(actionTitle) \(title)")
                }
                if failedCount > 0 {
                    Menu("More Actions", systemImage: "ellipsis") {
                        Button(
                            "Clear Failures", systemImage: "xmark.circle", role: .destructive, action: onClearFailures)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .accessibilityLabel("More \(title) actions")
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .disabled(isWorking)
        .padding(.vertical, PrismediaSpacing.small)
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
                accent: PrismediaColor.materialSpectrumGreen,
                onRun: {},
                onStop: {},
                onClearFailures: {}
            )
        }
    }
#endif
