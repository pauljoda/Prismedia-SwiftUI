import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityCandidateRow: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        let candidate: RequestActivityReleaseCandidate
        let layout: RequestActivityCandidateLayout
        let isDisabled: Bool
        let activeAction: RequestActivityCandidateAction?
        let onDownload: (RequestActivityReleaseCandidate) -> Void
        let onRequestBlocklist: (RequestActivityReleaseCandidate) -> Void

        var body: some View {
            switch layout {
            case .card:
                card
            case .dense:
                denseRow
            }
        }

        private var card: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                identity
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PrismediaSpacing.medium) { metadata }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) { metadata }
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textSecondary)
                actions
            }
            .padding(PrismediaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .prismediaPanel()
            .opacity(isDeemphasized ? 0.72 : 1)
            .accessibilityElement(children: .contain)
        }

        private var denseRow: some View {
            GridRow(alignment: .center) {
                identity
                    .gridColumnAlignment(.leading)
                Text(candidate.indexerName)
                    .lineLimit(1)
                    .gridColumnAlignment(.leading)
                Text(RequestActivityFormatting.bytes(candidate.sizeBytes))
                    .gridColumnAlignment(.trailing)
                Text(candidate.seeders.map(String.init) ?? "—")
                    .gridColumnAlignment(.trailing)
                Text(candidate.score, format: .number.precision(.fractionLength(0)))
                    .gridColumnAlignment(.trailing)
                actions
                    .gridColumnAlignment(.trailing)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(PrismediaColor.textSecondary)
            .padding(.vertical, PrismediaSpacing.small)
            .opacity(isDeemphasized ? 0.72 : 1)
            .accessibilityElement(children: .contain)
        }

        private var identity: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.small) {
                Image(systemName: RequestActivityReleasePolicy.categorySystemImage(for: category))
                    .foregroundStyle(PrismediaColor.textMuted)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(RequestActivityReleasePolicy.displayTitle(for: candidate))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: PrismediaSpacing.small) {
                            protocolLabel
                            dispositionLabel
                        }
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            protocolLabel
                            dispositionLabel
                        }
                    }

                    if let category {
                        Text(category)
                            .font(.caption2.monospaced())
                            .foregroundStyle(PrismediaColor.textMuted)
                    }

                    if !candidate.rejections.isEmpty {
                        Text(RequestActivityReleasePolicy.rejectionText(candidate))
                            .font(.caption)
                            .foregroundStyle(rejectionForegroundStyle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }

        private var protocolLabel: some View {
            Text(RequestActivityReleasePolicy.protocolLabel(for: candidate))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(PrismediaColor.textSecondary)
                .padding(.horizontal, PrismediaSpacing.small)
                .padding(.vertical, PrismediaSpacing.extraSmall / 2)
                .background(PrismediaColor.controlFill, in: .capsule)
        }

        private var dispositionLabel: some View {
            Label(
                RequestActivityReleasePolicy.statusLabel(for: candidate),
                systemImage: RequestActivityReleasePolicy.statusSystemImage(for: candidate)
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(dispositionForegroundStyle)
        }

        @ViewBuilder
        private var metadata: some View {
            if layout == .card {
                Text(candidate.indexerName)
                Text(RequestActivityFormatting.bytes(candidate.sizeBytes))
                Text(candidate.seeders.map { "\($0) seeders" } ?? "Seeders —")
                Text("Score \(candidate.score, format: .number.precision(.fractionLength(0)))")
            }
        }

        @ViewBuilder
        private var actions: some View {
            if hasActions {
                GlassEffectContainer(spacing: PrismediaSpacing.small) {
                    if layout == .card {
                        VStack(spacing: PrismediaSpacing.small) {
                            actionButtons(form: .fill)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        HStack(spacing: PrismediaSpacing.small) {
                            actionButtons(form: .automatic)
                        }
                    }
                }
                .frame(maxWidth: layout == .card ? .infinity : nil)
                .prismediaCompactActionControlSize()
            }
        }

        @ViewBuilder
        private func actionButtons(form: PrismediaButtonForm) -> some View {
            if canDownload {
                PrismediaButton(
                    disposition == .eligible ? "Download" : "Download Anyway",
                    systemImage: "arrow.down.circle",
                    variant: disposition == .eligible ? .prominent : .standard,
                    form: form,
                    primaryTint: disposition == .eligible ? artworkPrimaryAccent : nil,
                    isLoading: activeAction == .download(candidate.id),
                    loadingTitle: "Starting Download…"
                ) {
                    onDownload(candidate)
                }
                .disabled(isDisabled)
            }

            if activeAction == .blocklist(candidate.id) {
                PrismediaButton(
                    "Blocklist release",
                    systemImage: "hand.raised",
                    form: form,
                    isLoading: true,
                    loadingTitle: "Blocking…"
                ) {}
            } else if hasUtilityActions {
                PrismediaButton(
                    "More Actions",
                    systemImage: "ellipsis",
                    form: form
                ) {
                    if let infoURL {
                        Link(destination: infoURL) {
                            Label("Release Page", systemImage: "arrow.up.right.square")
                        }
                    }
                    if disposition == .eligible {
                        Button("Blocklist", systemImage: "hand.raised", role: .destructive) {
                            onRequestBlocklist(candidate)
                        }
                    }
                }
                .disabled(isDisabled)
            }
        }

        private var disposition: RequestActivityReleaseDisposition {
            RequestActivityReleasePolicy.disposition(of: candidate)
        }

        private var category: String? {
            RequestActivityReleasePolicy.category(for: candidate)
        }

        private var infoURL: URL? {
            RequestActivityReleasePolicy.validInfoURL(for: candidate)
        }

        private var canDownload: Bool {
            RequestActivityReleasePolicy.canManuallyQueue(candidate)
        }

        private var hasUtilityActions: Bool {
            infoURL != nil || disposition == .eligible
        }

        private var hasActions: Bool {
            canDownload || hasUtilityActions || activeAction == .blocklist(candidate.id)
        }

        private var isDeemphasized: Bool {
            [.unavailable, .blocklisted].contains(disposition)
        }

        private var dispositionForegroundStyle: Color {
            switch disposition {
            case .eligible: PrismediaColor.success
            case .overridable: PrismediaColor.warning
            case .unavailable: PrismediaColor.textMuted
            case .blocklisted: PrismediaColor.destructive
            }
        }

        private var rejectionForegroundStyle: Color {
            disposition == .blocklisted ? PrismediaColor.destructive : PrismediaColor.textMuted
        }
    }

    #if DEBUG
        #Preview("Request Activity Candidate") {
            RequestActivityCandidateRow(
                candidate: RequestActivityPreviewFixtures.candidate,
                layout: .card,
                isDisabled: false,
                activeAction: nil,
                onDownload: { _ in },
                onRequestBlocklist: { _ in }
            )
            .padding()
            .background(PrismediaBackdrop())
            .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
            .preferredColorScheme(.dark)
        }
    #endif
#endif
