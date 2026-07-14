import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityCandidateRow: View {
        let candidate: RequestActivityReleaseCandidate
        let isDisabled: Bool
        let onQueue: (RequestActivityReleaseCandidate) -> Void
        let onBlocklist: (RequestActivityReleaseCandidate) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text(candidate.title)
                    .font(.headline)
                    .textSelection(.enabled)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PrismediaSpacing.small) { metadata }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) { metadata }
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textSecondary)
                if !candidate.rejections.isEmpty {
                    Text(candidate.rejections.map(\.rawValue).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.destructive)
                }
                HStack {
                    PrismediaButton(
                        "Queue",
                        systemImage: "arrow.down.circle",
                        variant: .prominent
                    ) {
                        onQueue(candidate)
                    }
                    .disabled(isDisabled || !candidate.accepted)
                    PrismediaButton(
                        "Blocklist",
                        systemImage: "hand.raised",
                        variant: .destructive
                    ) {
                        onBlocklist(candidate)
                    }
                    .disabled(isDisabled)
                }
                .controlSize(.small)
            }
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .accessibilityElement(children: .contain)
        }

        @ViewBuilder
        private var metadata: some View {
            Text(candidate.indexerName)
            Text(RequestActivityFormatting.bytes(candidate.sizeBytes))
            Text(candidate.protocol.rawValue.uppercased())
            if let seeders = candidate.seeders { Text("\(seeders) seeders") }
            Text("Score \(candidate.score, format: .number.precision(.fractionLength(1)))")
        }
    }

    #if DEBUG
        #Preview("Request Activity Candidate") {
            RequestActivityCandidateRow(
                candidate: RequestActivityPreviewFixtures.candidate,
                isDisabled: false,
                onQueue: { _ in },
                onBlocklist: { _ in }
            )
            .padding()
        }
    #endif
#endif
