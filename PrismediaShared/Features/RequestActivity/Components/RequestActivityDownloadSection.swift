import SwiftUI

#if os(iOS) || os(macOS)
    /// The embedded live-transfer block: stage label, percent, progress bar, and the
    /// Speed / ETA / Seeds / Size stats grid — mirroring the web download section.
    struct RequestActivityDownloadSection: View {
        let transfer: RequestActivityTransfer?

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Text("Download")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                if let transfer {
                    transferContent(transfer)
                } else {
                    RequestActivityStatePlaceholder(
                        title: "Preparing download",
                        message:
                            "Connecting to the download client and waiting for the first progress report…",
                        systemImage: "arrow.down.circle",
                        isBusy: true
                    )
                }
            }
        }

        private func transferContent(_ transfer: RequestActivityTransfer) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                ProgressView(value: min(max(transfer.progress, 0), 1)) {
                    HStack {
                        if RequestActivityTransferPolicy.isActive(transfer.state) {
                            ProgressView()
                                .controlSize(.mini)
                        }
                        Text(RequestActivityTransferPolicy.stageLabel(for: transfer.state))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(transfer.progress, format: .percent.precision(.fractionLength(0)))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }
                .accessibilityValue(
                    Text(transfer.progress, format: .percent.precision(.fractionLength(0)))
                )

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: PrismediaSpacing.extraLarge) { stats(transfer) }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) { stats(transfer) }
                }
            }
            .padding(PrismediaSpacing.medium)
            .prismediaPanel()
        }

        @ViewBuilder
        private func stats(_ transfer: RequestActivityTransfer) -> some View {
            stat(
                "Speed",
                RequestActivityFormatting.speed(transfer.downloadSpeedBytesPerSecond)
            )
            stat("ETA", RequestActivityFormatting.eta(transfer.etaSeconds))
            stat("Seeds / Peers", "\(transfer.seeds) / \(transfer.peers)")
            stat("Size", RequestActivityFormatting.bytes(transfer.totalSizeBytes))
        }

        private func stat(_ label: String, _ value: String) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(PrismediaColor.textMuted)
                Text(value)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textPrimary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    #if DEBUG
        #Preview("Download Section") {
            VStack(spacing: PrismediaSpacing.large) {
                RequestActivityDownloadSection(transfer: RequestActivityPreviewFixtures.transfer)
                RequestActivityDownloadSection(transfer: nil)
            }
            .padding()
        }
    #endif
#endif
