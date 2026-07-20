import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyReviewActions: View {
        @Bindable var session: IdentifySession
        let item: AdministrativeIdentifyQueueItem

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
                                Task { await session.reject(advance: false) }
                            }
                            Button("Reject & Next") {
                                Task { await session.reject(advance: true) }
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
                                Task { await session.apply(advance: false) }
                            }
                            Button("Accept & Next") {
                                Task { await session.apply(advance: true) }
                            }
                        } label: {
                            Label("Accept", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(PrismediaColor.success)
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
