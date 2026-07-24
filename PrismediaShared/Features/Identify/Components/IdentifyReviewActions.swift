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
                Label("Review Actions", systemImage: "checkmark.seal")
                    .font(.headline)

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
                    LazyVGrid(
                        columns: [
                            GridItem(
                                .adaptive(minimum: 132),
                                spacing: PrismediaSpacing.medium
                            )
                        ],
                        spacing: PrismediaSpacing.medium
                    ) {
                        Button {
                            session.returnToSearch()
                        } label: {
                            Label("Back to Search", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .foregroundStyle(PrismediaColor.info)
                        .disabled(session.isApplying)

                        Menu {
                            Button("Reject") {
                                Task {
                                    if await session.reject(advance: false) {
                                        onRejected()
                                    }
                                }
                            }
                            Button("Reject & Next") {
                                Task {
                                    if await session.reject(advance: true) {
                                        onRejected()
                                    }
                                }
                            }
                        } label: {
                            Label("Reject", systemImage: "xmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .foregroundStyle(PrismediaColor.destructive)
                        .disabled(session.isApplying)

                        Menu {
                            Button("Accept") {
                                Task {
                                    if await session.apply(advance: false) {
                                        await onApplied()
                                    }
                                }
                            }
                            Button("Accept & Next") {
                                Task {
                                    if await session.apply(advance: true) {
                                        await onApplied()
                                    }
                                }
                            }
                        } label: {
                            Label("Accept", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(artworkPrimaryAccent)
                        .disabled(!canAccept)
                    }
                    .buttonBorderShape(.capsule)
                }

                if let disabledReason {
                    Label(disabledReason, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .accessibilityIdentifier("identify.review-actions.disabled-reason")
                }
            }
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
            .accessibilityIdentifier("identify.review-actions")
        }

        private var canAccept: Bool {
            item.proposal != nil && !item.cascadeRunning && !session.isApplying
        }

        private var disabledReason: String? {
            if session.isApplying {
                return "Review actions will be available when the current update finishes."
            }
            if item.cascadeRunning {
                return "Accept will be available when related metadata finishes identifying."
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
    #endif
#endif
