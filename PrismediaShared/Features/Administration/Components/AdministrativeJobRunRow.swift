import SwiftUI

struct AdministrativeJobRunRow: View {
    let job: AdministrativeJobRun
    let isWorking: Bool
    let onCancel: (AdministrativeJobRun) -> Void

    @State private var showsDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            #if os(tvOS)
                Button {
                    withAnimation {
                        showsDetails.toggle()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        HStack(alignment: .firstTextBaseline) {
                            Label(job.targetLabel ?? displayName, systemImage: statusImage)
                                .lineLimit(2)
                            Spacer(minLength: PrismediaSpacing.medium)
                            Text(job.status.capitalized)
                                .font(.caption)
                                .foregroundStyle(statusColor)
                            Image(systemName: showsDetails ? "chevron.up" : "chevron.down")
                        }

                        if showsProgress {
                            ProgressView(value: Double(job.progress), total: 100)
                                .accessibilityLabel("Progress")
                                .accessibilityValue("\(job.progress) percent")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }

                if showsDetails {
                    details
                }
            #else
            DisclosureGroup(isExpanded: $showsDetails) {
                details
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    HStack(alignment: .firstTextBaseline) {
                        Label(job.targetLabel ?? displayName, systemImage: statusImage)
                            .lineLimit(2)
                        Spacer(minLength: PrismediaSpacing.medium)
                        Text(job.status.capitalized)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }

                    if showsProgress {
                        ProgressView(value: Double(job.progress), total: 100)
                            .accessibilityLabel("Progress")
                            .accessibilityValue("\(job.progress) percent")
                    }
                }
            }
            #endif

            if job.isCancellable {
                Button("Cancel", systemImage: "stop.fill", role: .destructive) {
                    onCancel(job)
                }
                .disabled(isWorking)
            }
        }
        .padding(.vertical, PrismediaSpacing.extraSmall)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            if let message = job.message, !message.isEmpty {
                Text(message)
                    .font(.caption.monospaced())
                    #if !os(tvOS)
                        .textSelection(.enabled)
                    #endif
            }

            LabeledContent("Queued") {
                Text(job.createdAt, style: .relative)
            }
            if let startedAt = job.startedAt {
                LabeledContent("Started") {
                    Text(startedAt, style: .relative)
                }
            }
            if let finishedAt = job.finishedAt {
                LabeledContent("Finished") {
                    Text(finishedAt, style: .relative)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(PrismediaColor.textSecondary)
        .padding(.top, PrismediaSpacing.small)
    }

    private var displayName: String {
        job.type.replacingOccurrences(of: "-", with: " ").capitalized
    }

    private var showsProgress: Bool {
        ["active", "running"].contains(job.status.lowercased()) || job.progress > 0
    }

    private var statusImage: String {
        switch job.status.lowercased() {
        case "active", "running": "arrow.triangle.2.circlepath"
        case "waiting", "queued", "delayed": "clock"
        case "failed": "exclamationmark.triangle"
        case "completed": "checkmark.circle"
        default: "circle"
        }
    }

    private var statusColor: Color {
        switch job.status.lowercased() {
        case "failed": PrismediaColor.destructive
        case "active", "running": PrismediaColor.textPrimary
        default: PrismediaColor.textSecondary
        }
    }
}

#if DEBUG
    #Preview("Job Run") {
        List {
            AdministrativeJobRunRow(
                job: AdministrativeJobRun(
                    id: UUID(),
                    type: "identify-cascade",
                    status: "active",
                    progress: 62,
                    message: "Resolving Season 10",
                    targetKind: "video-series",
                    targetID: nil,
                    targetLabel: "MythBusters",
                    createdAt: .now.addingTimeInterval(-120),
                    startedAt: .now.addingTimeInterval(-90),
                    finishedAt: nil
                ),
                isWorking: false,
                onCancel: { _ in }
            )
        }
    }
#endif
