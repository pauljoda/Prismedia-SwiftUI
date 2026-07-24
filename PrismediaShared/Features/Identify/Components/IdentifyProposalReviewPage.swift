import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyProposalReviewPage: View {
        @Environment(\.artworkPrimaryAccent) private var inheritedPrimaryAccent
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @Bindable var session: IdentifySession
        let item: AdministrativeIdentifyQueueItem
        let proposal: AdministrativeEntityMetadataProposal
        let isRoot: Bool
        var onApplied: @MainActor () async -> Void = {}
        var onRejected: @MainActor () -> Void = {}
        @State private var childDestination: AdministrativeEntityMetadataProposal?
        @State private var artworkPalette: ArtworkPalette?

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                    if isRoot {
                        IdentifyTargetContextBar(item: currentItem)
                    }

                    if currentItem.cascadeRunning, isRoot {
                        Label("Identifying related metadata", systemImage: "arrow.triangle.branch")
                            .foregroundStyle(PrismediaColor.warning)
                    }

                    MetadataProposalReviewView(
                        proposal: currentProposal,
                        selection: $session.reviewSelection,
                        selectedProposalIDs: selectedProposalIDs,
                        selectableProposalIDs: selectableProposalIDs,
                        childrenTitle: "Children",
                        onSetProposalSelected: setProposalSelected,
                        onActivateProposal: { childDestination = $0 }
                    )

                    IdentifyReviewActions(
                        session: session,
                        item: currentItem,
                        onApplied: onApplied,
                        onRejected: onRejected
                    )
                }
                .id(currentProposal.proposalID)
                .padding()
            }
            .prismediaScreenBackground()
            .navigationTitle(isRoot ? currentItem.title : currentProposal.patch.title ?? currentItem.title)
            .environment(\.artworkPalette, artworkPalette)
            .environment(\.artworkPrimaryAccent, primaryAccent)
            .prismediaArtworkPalette(
                for: MetadataReviewArtworkPolicy.primaryArtworkPath(for: currentProposal),
                palette: $artworkPalette
            )
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(item: $childDestination) { child in
                IdentifyProposalReviewPage(
                    session: session,
                    item: currentItem,
                    proposal: child,
                    isRoot: false,
                    onApplied: onApplied,
                    onRejected: onRejected
                )
            }
            .task(id: refreshTaskID) {
                guard liveRefreshIsActive else { return }
                await session.refreshSelectedItem()
                await pollSelectedItemWhileVisible()
            }
        }

        private var currentItem: AdministrativeIdentifyQueueItem {
            session.selectedItem ?? item
        }

        private var currentProposal: AdministrativeEntityMetadataProposal {
            guard let root = currentItem.proposal else { return proposal }
            return MetadataReviewPolicy.proposal(withID: proposal.proposalID, in: root) ?? proposal
        }

        private var primaryAccent: Color {
            artworkPalette?.primary.color ?? inheritedPrimaryAccent
        }

        private var directNodes: [AdministrativeEntityMetadataProposal] {
            MetadataReviewPolicy.relationships(of: currentProposal)
                + MetadataReviewPolicy.structuralChildren(of: currentProposal)
        }

        private var selectableProposalIDs: Set<String> {
            Set(directNodes.map(\.proposalID))
        }

        private var selectedProposalIDs: Set<String> {
            selectableProposalIDs.subtracting(session.reviewSelection.excludedProposalIDs)
        }

        private var liveRefreshIsActive: Bool {
            pageIsActive && scenePhase == .active && session.selectedItemID != nil
        }

        private var refreshTaskID: String {
            "\(session.selectedItemID?.uuidString ?? "none"):\(liveRefreshIsActive)"
        }

        private func pollSelectedItemWhileVisible() async {
            while liveRefreshIsActive {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                guard !Task.isCancelled, liveRefreshIsActive else { return }
                await session.refreshSelectedItem()
            }
        }

        private func setProposalSelected(_ proposalID: String, _ isSelected: Bool) {
            if isSelected {
                session.reviewSelection.excludedProposalIDs.remove(proposalID)
            } else {
                session.reviewSelection.excludedProposalIDs.insert(proposalID)
            }
        }
    }

    #if DEBUG
        #Preview("Proposal Review Page") {
            let session = IdentifySession(
                service: AdministrativePreviewService(),
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [IdentifyPreviewFixtures.reviewItem],
                initialProviders: [IdentifyPreviewFixtures.provider]
            )
            PreviewShell {
                NavigationStack {
                    IdentifyProposalReviewPage(
                        session: session,
                        item: IdentifyPreviewFixtures.reviewItem,
                        proposal: IdentifyPreviewFixtures.reviewItem.proposal!,
                        isRoot: true
                    )
                }
            }
        }
    #endif
#endif
