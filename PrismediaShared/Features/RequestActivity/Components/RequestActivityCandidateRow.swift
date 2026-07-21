import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityCandidateRow: View {
        let candidate: RequestActivityReleaseCandidate
        let isDisabled: Bool
        let variant: RequestActivityCandidateRowVariant
        let onQueue: (RequestActivityReleaseCandidate) -> Void
        let onBlocklist: (RequestActivityReleaseCandidate) -> Void

        init(
            candidate: RequestActivityReleaseCandidate,
            isDisabled: Bool,
            variant: RequestActivityCandidateRowVariant = .queue,
            onQueue: @escaping (RequestActivityReleaseCandidate) -> Void,
            onBlocklist: @escaping (RequestActivityReleaseCandidate) -> Void
        ) {
            self.candidate = candidate
            self.isDisabled = isDisabled
            self.variant = variant
            self.onQueue = onQueue
            self.onBlocklist = onBlocklist
        }

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
                    Text(rejectionText)
                        .font(.caption)
                        .foregroundStyle(rejectionStyle)
                }
                ViewThatFits(in: .horizontal) {
                    GlassEffectContainer(spacing: PrismediaSpacing.small) {
                        HStack(spacing: PrismediaSpacing.small) {
                            actionButtons
                        }
                    }
                    GlassEffectContainer(spacing: PrismediaSpacing.small) {
                        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                            actionButtons
                        }
                    }
                }
                .prismediaCompactActionControlSize()
            }
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .accessibilityElement(children: .contain)
        }

        @ViewBuilder
        private var actionButtons: some View {
            PrismediaButton(
                primaryActionTitle,
                systemImage: "arrow.down.circle",
                variant: primaryActionVariant
            ) {
                onQueue(candidate)
            }
            .disabled(isDisabled || !canQueue)
            PrismediaButton(
                "Blocklist",
                systemImage: "hand.raised",
                variant: .destructive
            ) {
                onBlocklist(candidate)
            }
            .disabled(isDisabled)
        }

        private var primaryActionTitle: String {
            switch variant {
            case .queue: "Queue"
            case .download: candidate.accepted ? "Download" : "Download anyway"
            }
        }

        private var primaryActionVariant: PrismediaButtonVariant {
            switch variant {
            case .queue: .prominent
            case .download: candidate.accepted ? .prominent : .standard
            }
        }

        private var canQueue: Bool {
            switch variant {
            case .queue: candidate.accepted
            case .download: RequestActivityReleasePolicy.canManuallyQueue(candidate)
            }
        }

        private var rejectionText: String {
            switch variant {
            case .queue: candidate.rejections.map(\.rawValue).joined(separator: " · ")
            case .download: RequestActivityReleasePolicy.rejectionText(candidate)
            }
        }

        private var rejectionStyle: Color {
            switch variant {
            case .queue: PrismediaColor.destructive
            case .download: PrismediaColor.textMuted
            }
        }

        @ViewBuilder
        private var metadata: some View {
            Text(candidate.indexerName)
            Text(RequestActivityFormatting.bytes(candidate.sizeBytes))
            Text(protocolLabel)
            if let seeders = candidate.seeders { Text("\(seeders) seeders") }
            Text("Score \(candidate.score, format: .number.precision(.fractionLength(1)))")
        }

        private var protocolLabel: String {
            switch variant {
            case .queue: candidate.protocol.rawValue.uppercased()
            case .download: candidate.protocol == .usenet ? "Usenet" : "Torrent"
            }
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
