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
                    IdentifyTargetContextBar(
                        item: currentItem,
                        thumbnail: session.selectedEntityThumbnail,
                        isLoading: session.isLoadingSelectedEntityDetail
                    )

                    if currentItem.cascadeRunning, isRoot {
                        Label("Identifying related metadata", systemImage: "arrow.triangle.branch")
                            .foregroundStyle(PrismediaColor.warning)
                    }

                    MetadataProposalReviewView(
                        proposal: currentProposal,
                        selection: $session.reviewSelection,
                        selectedProposalIDs: selectedProposalIDs,
                        selectableProposalIDs: selectableProposalIDs,
                        childrenTitle: newContainersTitle,
                        displayedChildren: displayedProposalChildren,
                        existingTagTitles: existingTagTitles,
                        onSetProposalSelected: setProposalSelected,
                        onActivateProposal: { childDestination = $0 }
                    )

                    if isRoot, !childReviewItems.isEmpty {
                        IdentifyChildrenReviewSection(
                            items: childReviewItems,
                            selectedProposalIDs: selectedProposalIDs,
                            cascadeRunning: currentItem.cascadeRunning,
                            onSetProposalSelected: setProposalSelected,
                            onActivateProposal: { childDestination = $0 }
                        )
                    }

                    if isRoot {
                        IdentifyReviewActions(
                            session: session,
                            item: currentItem,
                            onApplied: onApplied,
                            onRejected: onRejected
                        )
                    }
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
                await session.loadSelectedEntityDetail()
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

        private var reviewNodes: [AdministrativeEntityMetadataProposal] {
            MetadataReviewPolicy.relationships(of: currentProposal)
                + MetadataReviewPolicy.structuralDescendants(of: currentProposal)
        }

        private var selectableProposalIDs: Set<String> {
            Set(reviewNodes.map(\.proposalID))
        }

        private var selectedProposalIDs: Set<String> {
            selectableProposalIDs.subtracting(session.reviewSelection.excludedProposalIDs)
        }

        private var localChildren: [EntityThumbnail] {
            guard isRoot else { return [] }
            return session.selectedEntityDetail?.childrenByKind.flatMap(\.entities) ?? []
        }

        private var remainingLocalChildren: [EntityThumbnail] {
            IdentifyChildReviewPolicy.remainingChildren(
                localChildren,
                in: currentProposal
            )
        }

        private var childReviewItems: [IdentifyChildReviewItem] {
            IdentifyChildReviewPolicy.items(
                children: remainingLocalChildren,
                proposal: currentProposal,
                cascadeRunning: currentItem.cascadeRunning
            )
        }

        private var displayedProposalChildren: [AdministrativeEntityMetadataProposal]? {
            guard isRoot, !localChildren.isEmpty else { return nil }
            return IdentifyChildReviewPolicy.newContainers(in: currentProposal)
        }

        private var newContainersTitle: String {
            guard let kind = displayedProposalChildren?.first?.targetKind else {
                return "Children"
            }
            return "New \(EntityKind(rawValue: kind).displayLabel)"
        }

        private var existingTagTitles: Set<String> {
            guard isRoot else { return [] }
            let tags =
                session.selectedEntityDetail?.relationships
                .filter { $0.kind == .tag }
                .flatMap(\.entities)
                .map(\.title)
                ?? []
            return Set(tags)
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
            MetadataReviewPolicy.setProposal(
                proposalID,
                selected: isSelected,
                within: currentProposal,
                selection: &session.reviewSelection
            )
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
