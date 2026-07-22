import SwiftUI

struct EntityChildMonitoringRow: View {
    let item: EntityChildMonitoringItem
    let isBusy: Bool
    let primaryAccent: Color
    let onToggle: @MainActor @Sendable (Bool) -> Void
    let onRetryCleanup: @MainActor @Sendable () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            if let isOn = item.isOn {
                Toggle(
                    isOn: Binding(get: { isOn }, set: { onToggle($0) })
                ) {
                    rowLabel
                }
                .disabled(isBusy || item.command(to: !isOn) == nil)
                .tint(primaryAccent)
            } else {
                HStack(spacing: PrismediaSpacing.medium) {
                    rowLabel
                    Spacer(minLength: PrismediaSpacing.medium)
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }

            if item.canRetryCleanup {
                Button("Retry Cleanup", systemImage: "arrow.clockwise", action: onRetryCleanup)
                    .buttonStyle(.borderless)
                    .foregroundStyle(PrismediaColor.warning)
                    .disabled(isBusy)
            }
        }
        .padding(.vertical, PrismediaSpacing.extraSmall)
        .accessibilityIdentifier("entity-detail.acquisition.child.\(item.id.uuidString)")
    }

    private var rowLabel: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            HStack(spacing: PrismediaSpacing.small) {
                Text(item.entity.title)
                    .foregroundStyle(PrismediaColor.textPrimary)
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                }
            }
            Text(statusLabel)
                .font(.caption)
                .foregroundStyle(PrismediaColor.textSecondary)
        }
    }

    private var statusLabel: LocalizedStringKey {
        guard let monitor = item.state.monitor else {
            return item.state.canMonitor || item.state.canRequest ? "Not monitored" : "Unavailable"
        }
        switch monitor.status {
        case .active: return "Active"
        case .paused: return "Paused"
        case .fulfilled: return "Goal fulfilled"
        case .deletingFiles: return "Deleting files"
        case .stopping: return "Cleanup needs attention"
        default: return "Unknown status"
        }
    }
}

#if DEBUG
    #Preview("Child Monitoring Row") {
        let entity = EntityAcquisitionPanelPreviewFixtures.childGroup.entities[0]
        EntityChildMonitoringRow(
            item: EntityChildMonitoringItem(
                entity: entity,
                state: EntityAcquisitionPanelPreviewFixtures.childStates[entity.id]!
            ),
            isBusy: false,
            primaryAccent: PrismediaColor.spectrumCyan,
            onToggle: { _ in },
            onRetryCleanup: {}
        )
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
