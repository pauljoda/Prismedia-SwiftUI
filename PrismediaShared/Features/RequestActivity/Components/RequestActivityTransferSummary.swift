import SwiftUI

#if os(iOS) || os(macOS)
    /// Native live-transfer summary shared by compact and regular-width entity
    /// Acquisition layouts. The lifecycle owns actions; this view is read-only.
    struct RequestActivityTransferSummary: View {
        let transfer: RequestActivityTransfer
        let isStale: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                stageHeader
                progress
                primaryMetrics
                secondaryTelemetry
                if !transfer.pieceStates.isEmpty {
                    RequestActivityPieceStateBar(pieces: transfer.pieceStates)
                }
                if isStale { staleNotice }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.medium)
            .prismediaPanel()
        }

        private var stageHeader: some View {
            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                Label(
                    RequestActivityTransferPolicy.stageLabel(for: transfer.state),
                    systemImage: RequestActivityTransferPolicy.systemImage(for: transfer.state)
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RequestActivityTransferPolicy.tone(for: transfer.state).foregroundStyle)

                Spacer(minLength: PrismediaSpacing.medium)

                Text(clampedProgress, format: .percent.precision(.fractionLength(0)))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(PrismediaColor.textPrimary)
            }
            .accessibilityElement(children: .combine)
        }

        private var progress: some View {
            ProgressView(value: clampedProgress)
                .tint(RequestActivityTransferPolicy.tone(for: transfer.state).foregroundStyle)
                .accessibilityLabel("Download progress")
                .accessibilityValue(progressAccessibilityValue)
        }

        private var primaryMetrics: some View {
            ViewThatFits(in: .horizontal) {
                Grid(alignment: .leading, horizontalSpacing: PrismediaSpacing.extraLarge) {
                    GridRow {
                        metric("Downloaded", downloadedValue)
                        metric("Speed", speedValue)
                        metric("ETA", etaValue)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    labeledMetric("Downloaded", downloadedValue)
                    labeledMetric("Speed", speedValue)
                    labeledMetric("ETA", etaValue)
                }
            }
        }

        @ViewBuilder
        private var secondaryTelemetry: some View {
            if RequestActivityTransferPolicy.showsSwarmTelemetry(transfer) {
                LabeledContent("Swarm") {
                    Text("\(transfer.seeds) seeds · \(transfer.peers) peers")
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(PrismediaColor.textSecondary)
                .accessibilityElement(children: .combine)
            }
        }

        private var staleNotice: some View {
            Label(
                "Live transfer data may be out of date. Prismedia is still retrying.",
                systemImage: "wifi.exclamationmark"
            )
            .font(.caption)
            .foregroundStyle(PrismediaColor.warning)
            .accessibilityElement(children: .combine)
        }

        private func metric(_ label: String, _ value: String) -> some View {
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

        private func labeledMetric(_ label: String, _ value: String) -> some View {
            LabeledContent(label) {
                Text(value)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(PrismediaColor.textPrimary)
            .accessibilityElement(children: .combine)
        }

        private var downloadedValue: String {
            guard transfer.totalSizeBytes > 0 else { return "Calculating…" }
            let downloaded = Int64(Double(transfer.totalSizeBytes) * clampedProgress)
            return
                "\(RequestActivityFormatting.bytes(downloaded)) / \(RequestActivityFormatting.bytes(transfer.totalSizeBytes))"
        }

        private var speedValue: String {
            guard transfer.downloadSpeedBytesPerSecond > 0 else {
                return RequestActivityTransferPolicy.expectsDownloadTelemetry(transfer.state)
                    ? "Waiting…"
                    : "—"
            }
            return RequestActivityFormatting.speed(transfer.downloadSpeedBytesPerSecond)
        }

        private var etaValue: String {
            if RequestActivityTransferPolicy.isComplete(transfer.state) { return "Complete" }
            guard transfer.etaSeconds > 0 else {
                return RequestActivityTransferPolicy.expectsDownloadTelemetry(transfer.state)
                    ? "Calculating…"
                    : "—"
            }
            return RequestActivityFormatting.eta(transfer.etaSeconds)
        }

        private var progressAccessibilityValue: Text {
            Text(
                "\(RequestActivityTransferPolicy.stageLabel(for: transfer.state)), \(clampedProgress.formatted(.percent.precision(.fractionLength(0)))), \(downloadedValue)"
            )
        }

        private var clampedProgress: Double {
            min(max(transfer.progress, 0), 1)
        }
    }

    #if DEBUG
        #Preview("Transfer Summary") {
            RequestActivityTransferSummary(
                transfer: RequestActivityPreviewFixtures.transfer,
                isStale: false
            )
            .padding()
        }
    #endif
#endif
