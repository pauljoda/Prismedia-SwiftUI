import SwiftUI

struct AdministrativeDatabaseRestoreView: View {
    @State private var phase = AdministrativeDatabaseRestorePhase.connecting
    let service: any DatabaseBackupServicing
    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: PrismediaSpacing.extraLarge) {
            Image(systemName: systemImage).font(.system(size: 52)).foregroundStyle(tone)
            Text(title).font(.title2.bold())
            Text(detail).multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 560)
            if case .failed(let error) = phase {
                Text(error).font(.caption.monospaced()).prismediaTextSelection().foregroundStyle(
                    PrismediaColor.destructive)
            }
            switch phase {
            case .complete:
                Button("Return to Sign In", action: onFinished).buttonStyle(.glassProminent)
            case .failed:
                HStack {
                    Button("Check Again") { Task { await pollOnce() } }
                    Button("Return to Sign In", action: onFinished)
                }
            default:
                ProgressView()
            }
        }
        .padding(PrismediaSpacing.section)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .prismediaScreenBackground()
        .task { await monitor() }
        .accessibilityIdentifier("database.restore.progress")
    }

    private var title: String {
        switch phase {
        case .complete: "Restore Complete"
        case .failed: "Restore Failed"
        default: "Restoring Database"
        }
    }
    private var detail: String {
        switch phase {
        case .connecting: "Prismedia is restarting. This screen reconnects automatically."
        case .restoring: "The selected backup is replacing the current database. Prismedia may be unavailable briefly."
        case .complete: "Prismedia is ready. Sign in again to establish a fresh session."
        case .failed:
            "The server could not complete the restore. Review the error, then check again or return to sign in."
        }
    }
    private var systemImage: String {
        switch phase {
        case .complete: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        default: "externaldrive.badge.timemachine"
        }
    }
    private var tone: Color {
        switch phase {
        case .complete: PrismediaColor.success
        case .failed: PrismediaColor.destructive
        default: PrismediaColor.accent
        }
    }

    private func monitor() async {
        while !Task.isCancelled {
            await pollOnce()
            if case .complete = phase { return }
            if case .failed = phase { return }
            try? await Task.sleep(for: .seconds(1.5))
        }
    }

    private func pollOnce() async {
        do {
            let status = try await service.restoreStatus()
            if status.restoreFailed {
                phase = .failed(status.error ?? "The server did not provide an error.")
            } else if status.restorePending {
                phase = .restoring
            } else {
                phase = .complete
            }
        } catch { phase = .connecting }
    }
}

#if DEBUG
    #Preview("Restore Lifecycle") {
        AdministrativeDatabaseRestoreView(service: Step3AdministrationPreviewService(), onFinished: {})
    }
#endif
