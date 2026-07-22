import SwiftUI

struct EntityMonitorControl: View {
    let monitorState: EntityMonitorState?
    let presentation: EntityMonitorPresentation
    let primaryAccent: Color
    let onChange: @MainActor @Sendable (Bool) -> Void

    var body: some View {
        Group {
            if let isOn = presentation.isOn {
                Toggle(
                    isOn: Binding(
                        get: { isOn },
                        set: { onChange($0) }
                    )
                ) {
                    label
                }
                .disabled(!presentation.isEnabled)
                .tint(primaryAccent)
                .accessibilityHint(toggleHint(isOn: isOn))
            } else {
                HStack(alignment: .center, spacing: PrismediaSpacing.medium) {
                    label
                    Spacer(minLength: PrismediaSpacing.large)
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .accessibilityIdentifier("entity-detail.acquisition.monitor")
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            HStack(spacing: PrismediaSpacing.small) {
                Text("Monitor")
                    .font(.title3)
                    .foregroundStyle(PrismediaColor.textPrimary)
                if presentation.isBusy, presentation.isOn != nil {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                }
            }
            statusText
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        if presentation.isAwaitingRefresh {
            Text("Monitoring changed. Refreshing the latest status…")
        } else if presentation.isBusy, presentation.isOn == true {
            Text("Turning on monitoring…")
        } else if presentation.isBusy, presentation.isOn == false {
            Text("Stopping monitoring…")
        } else if let monitorState {
            if let monitor = monitorState.monitor {
                switch monitor.status {
                case .active:
                    if monitorState.discoversChildren {
                        if providerSummary.isEmpty {
                            Text("Checks daily for new content.")
                        } else {
                            Text("Checks daily for new content via \(providerSummary).")
                        }
                    } else if providerSummary.isEmpty {
                        Text("Actively monitoring this item.")
                    } else {
                        Text("Monitoring via \(providerSummary).")
                    }
                case .paused:
                    Text("Paused. Turn Monitor on to resume.")
                case .fulfilled:
                    Text("Goal fulfilled. Turn Monitor on to watch for changes.")
                case .deletingFiles:
                    Text("Monitoring stays on while files are being deleted.")
                case .stopping:
                    Text("Stopping and cleaning up files…")
                default:
                    Text("Monitoring returned an unfamiliar status. Changes are disabled for safety.")
                }
            } else if monitorState.canMonitor {
                if providerSummary.isEmpty {
                    Text("Off")
                } else {
                    Text("Available via \(providerSummary).")
                }
            } else if monitorState.trackableProviders.isEmpty {
                Text("Unavailable until this item is matched to a supported provider.")
            } else {
                Text("Monitoring is unavailable for this item.")
            }
        } else {
            Text("Checking monitoring status…")
        }
    }

    private var providerSummary: String {
        monitorState?.trackableProviders.joined(separator: ", ") ?? ""
    }

    private func toggleHint(isOn: Bool) -> Text {
        if presentation.isEnabled {
            return Text(
                isOn
                    ? "Turns off monitoring after confirmation"
                    : "Turns on monitoring for this item"
            )
        }
        return Text("Monitoring cannot be changed right now")
    }
}

#if DEBUG
    #Preview("Monitor Control · Loading") {
        EntityMonitorControl(
            monitorState: nil,
            presentation: EntityMonitorPresentation(
                state: nil,
                isMutating: false,
                pendingValue: nil
            ),
            primaryAccent: PrismediaColor.spectrumCyan,
            onChange: { _ in }
        )
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
