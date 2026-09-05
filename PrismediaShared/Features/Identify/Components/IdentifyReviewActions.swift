import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyReviewActions: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @Bindable var session: IdentifySession
        let item: AdministrativeIdentifyQueueItem
        var onApplied: @MainActor () async -> Void = {}
        var onRejected: @MainActor () -> Void = {}

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                if let progress = session.applyProgress {
                    ProgressView(
                        value: Double(progress.currentIndex),
                        total: Double(max(progress.total, 1))
                    ) {
                        Text(progress.currentTitle ?? "Applying metadata")
                    }
                    .tint(artworkPrimaryAccent)
                }

                if let errorMessage = session.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(PrismediaColor.destructive)
                }

                GlassEffectContainer(spacing: PrismediaSpacing.medium) {
                    HStack(alignment: .center, spacing: PrismediaSpacing.medium) {
                        PrismediaButton(
                            "More actions",
                            systemImage: "ellipsis",
                            form: .compactIcon
                        ) {
                            Button("Back to Search", systemImage: "magnifyingglass") {
                                session.returnToSearch()
                            }

                            if session.reviewableIDs.count > 1 {
                                Button("Accept & Next", systemImage: "checkmark") {
                                    apply(advance: true)
                                }
                                .disabled(!canAccept)
                            }

                            Divider()

                            Button("Reject", systemImage: "xmark", role: .destructive) {
                                reject(advance: false)
                            }
                            if session.reviewableIDs.count > 1 {
                                Button("Reject & Next", systemImage: "forward.end", role: .destructive) {
                                    reject(advance: true)
                                }
                            }
                        }
                        .disabled(session.isMutatingQueue)
                        .accessibilityIdentifier("identify.review-actions.more")

                        PrismediaButton(
                            session.isApplying ? "Applying…" : "Accept",
                            systemImage: "checkmark",
                            variant: .prominent,
                            form: .fill,
                            primaryTint: artworkPrimaryAccent,
                            isLoading: session.isApplying,
                            action: { apply(advance: false) }
                        )
                        .disabled(!canAccept || session.isMutatingQueue)
                        .accessibilityIdentifier("identify.review-actions.accept")
                    }
                    .frame(maxWidth: .infinity)
                }

                if let disabledReason {
                    Label(disabledReason, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .accessibilityIdentifier("identify.review-actions.disabled-reason")
                }
            }
            .accessibilityIdentifier("identify.review-actions")
        }

        private func apply(advance: Bool) {
            Task {
                if await session.apply(advance: advance) {
                    await onApplied()
                }
            }
        }

        private func reject(advance: Bool) {
            Task {
                if await session.reject(advance: advance) {
                    onRejected()
                }
            }
        }

        private var canAccept: Bool {
            item.proposal != nil && !item.cascadeRunning && !session.isApplying
        }

        private var disabledReason: String? {
            if session.isApplying {
                return nil
            }
            if item.cascadeRunning {
                return "Waiting for related metadata to finish."
            }
            if item.proposal == nil {
                return "Choose a metadata match before accepting this item."
            }
            return nil
        }
    }

    #if DEBUG
        #Preview("Review Actions · Ready") {
            PreviewShell {
                IdentifyReviewActions(
                    session: .init(
                        service: AdministrativePreviewService(),
                        browser: IdentifyPreviewEntityBrowser(),
                        initialQueue: [IdentifyPreviewFixtures.reviewItem],
                        initialProviders: [IdentifyPreviewFixtures.provider]
                    ),
                    item: IdentifyPreviewFixtures.reviewItem
                )
                .padding()
            }
        }

        #Preview("Review Actions · Large Text") {
            PreviewShell {
                IdentifyReviewActions(
                    session: .init(
                        service: AdministrativePreviewService(),
                        browser: IdentifyPreviewEntityBrowser(),
                        initialQueue: [IdentifyPreviewFixtures.reviewItem],
                        initialProviders: [IdentifyPreviewFixtures.provider]
                    ),
                    item: IdentifyPreviewFixtures.reviewItem
                )
                .padding()
                .environment(\.dynamicTypeSize, .accessibility3)
            }
        }
    #endif
#endif
