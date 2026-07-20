import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyReviewView: View {
        @Bindable var session: IdentifySession
        @State private var proposalPath: [String] = []

        var body: some View {
            if let item = session.selectedItem {
                Group {
                    if let proposal = item.proposal, !session.showsSearchForProposal {
                        proposalReview(item: item, root: proposal)
                    } else {
                        searchSurface(item)
                    }
                }
                .navigationTitle(item.title)
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar { reviewNavigation }
                .onChange(of: session.selectedItemID) { _, _ in
                    proposalPath = []
                }
                .onChange(of: item.proposal?.proposalID) { _, _ in
                    proposalPath = []
                }
                .accessibilityIdentifier("identify.review")
            } else {
                ContentUnavailableView(
                    "Choose an Item", systemImage: "checklist",
                    description: Text("Select an identify queue item to search or review metadata."))
            }
        }

        private func searchSurface(_ item: AdministrativeIdentifyQueueItem) -> some View {
            PluginSearchSurface(
                title: "Find Metadata",
                description: "Search installed plugins and choose the correct match.",
                entityKind: item.entityKind.rawValue, hidesNsfw: session.hidesNsfw,
                seedTitle: item.title,
                providers: session.providers, selectedProviderID: $session.selectedProviderID,
                values: $session.searchValues, candidates: item.candidates,
                hasSearched: item.query != nil || !item.candidates.isEmpty,
                isSearching: session.isSearching, isDisabled: item.cascadeRunning,
                errorMessage: item.error,
                searchStatus: session.isSeeking ? "Seeking across providers…" : nil,
                onSearch: { values in Task { await session.search(fields: values) } },
                onClear: { session.searchValues.removeAll() },
                onCandidateActivate: { candidate in Task { await session.resolve(candidate) } },
                onRescan: { Task { await session.rescan() } },
                isRescanning: session.isSearching,
                onSeek: { Task { await session.seek() } },
                isSeeking: session.isSeeking
            )
            .safeAreaInset(edge: .top, spacing: 0) {
                IdentifyTargetContextBar(item: item)
                    .padding(.horizontal)
                    .padding(.bottom, PrismediaSpacing.small)
            }
        }

        private func proposalReview(
            item: AdministrativeIdentifyQueueItem,
            root: AdministrativeEntityMetadataProposal
        ) -> some View {
            let context = proposalContext(root: root)
            let nodes = directNodes(of: context.current)
            let selectableIDs = Set(nodes.map(\.proposalID))
            let selectedIDs = selectableIDs.subtracting(session.reviewSelection.excludedProposalIDs)

            return ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                    if proposalPath.isEmpty {
                        IdentifyTargetContextBar(item: item)
                    }

                    if let parent = context.parent {
                        IdentifyProposalScopeHeader(
                            parentTitle: parent.patch.title ?? item.title,
                            siblingIndex: context.siblingIndex,
                            siblingCount: context.siblings.count,
                            onOpenParent: openParentProposal,
                            onOpenPrevious: { openSibling(at: context.siblingIndex - 1, in: context.siblings) },
                            onOpenNext: { openSibling(at: context.siblingIndex + 1, in: context.siblings) }
                        )
                    }

                    if item.cascadeRunning, proposalPath.isEmpty {
                        Label("Identifying related metadata", systemImage: "arrow.triangle.branch")
                            .foregroundStyle(PrismediaColor.warning)
                    }

                    MetadataProposalReviewView(
                        proposal: context.current,
                        selection: $session.reviewSelection,
                        selectedProposalIDs: selectedIDs,
                        selectableProposalIDs: selectableIDs,
                        childrenTitle: "Children",
                        onSetProposalSelected: setProposalSelected,
                        onActivateProposal: openChildProposal
                    )

                    applyActions(item)
                }
                .id(context.current.proposalID)
                .padding()
            }
        }

        private func proposalContext(
            root: AdministrativeEntityMetadataProposal
        ) -> (
            current: AdministrativeEntityMetadataProposal,
            parent: AdministrativeEntityMetadataProposal?,
            siblings: [AdministrativeEntityMetadataProposal],
            siblingIndex: Int
        ) {
            var current = root
            var parent: AdministrativeEntityMetadataProposal?
            var siblings: [AdministrativeEntityMetadataProposal] = []
            var siblingIndex = 0

            for proposalID in proposalPath {
                let relationshipSiblings = MetadataReviewPolicy.relationships(of: current)
                let structuralSiblings = MetadataReviewPolicy.structuralChildren(of: current)
                let availableSiblings =
                    relationshipSiblings.contains(where: { $0.proposalID == proposalID })
                    ? relationshipSiblings
                    : structuralSiblings
                guard let next = availableSiblings.first(where: { $0.proposalID == proposalID }) else { break }
                parent = current
                siblings = availableSiblings
                siblingIndex = siblings.firstIndex(where: { $0.proposalID == proposalID }) ?? -1
                current = next
            }

            return (current, parent, siblings, siblingIndex)
        }

        private func directNodes(
            of proposal: AdministrativeEntityMetadataProposal
        ) -> [AdministrativeEntityMetadataProposal] {
            MetadataReviewPolicy.relationships(of: proposal)
                + MetadataReviewPolicy.structuralChildren(of: proposal)
        }

        private func openChildProposal(_ proposal: AdministrativeEntityMetadataProposal) {
            proposalPath.append(proposal.proposalID)
        }

        private func openParentProposal() {
            guard !proposalPath.isEmpty else { return }
            proposalPath.removeLast()
        }

        private func openSibling(
            at index: Int,
            in siblings: [AdministrativeEntityMetadataProposal]
        ) {
            guard siblings.indices.contains(index), !proposalPath.isEmpty else { return }
            proposalPath[proposalPath.count - 1] = siblings[index].proposalID
        }

        private func setProposalSelected(_ proposalID: String, _ isSelected: Bool) {
            if isSelected {
                session.reviewSelection.excludedProposalIDs.remove(proposalID)
            } else {
                session.reviewSelection.excludedProposalIDs.insert(proposalID)
            }
        }

        private func applyActions(_ item: AdministrativeIdentifyQueueItem) -> some View {
            GroupBox("Review Actions") {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    if let progress = session.applyProgress {
                        ProgressView(value: Double(progress.currentIndex), total: Double(max(progress.total, 1))) {
                            Text(progress.currentTitle ?? "Applying metadata")
                        }
                    }

                    ControlGroup {
                        Button("Back to Search", systemImage: "arrow.left", action: session.returnToSearch)

                        Menu("Reject", systemImage: "xmark") {
                            Button("Reject") {
                                Task { await session.reject(advance: false) }
                            }
                            Button("Reject & Next") {
                                Task { await session.reject(advance: true) }
                            }
                        }

                        Menu("Accept", systemImage: "checkmark") {
                            Button("Accept") {
                                Task { await session.apply(advance: false) }
                            }
                            Button("Accept & Next") {
                                Task { await session.apply(advance: true) }
                            }
                        }
                        .disabled(session.isApplying || item.cascadeRunning)
                    }
                }
                .padding(.vertical, PrismediaSpacing.small)
            }
        }

        @ToolbarContentBuilder private var reviewNavigation: some ToolbarContent {
            ToolbarItemGroup {
                Button(action: session.selectPrevious) {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Previous")
                .disabled(session.reviewableIDs.count < 2)

                Button(action: session.selectNext) {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("Next")
                .disabled(session.reviewableIDs.count < 2)
            }
        }
    }

    #if DEBUG
        #Preview("Review · Proposal") {
            NavigationStack {
                IdentifyReviewView(
                    session: .init(
                        service: AdministrativePreviewService(), browser: IdentifyPreviewEntityBrowser(),
                        initialQueue: [IdentifyPreviewFixtures.reviewItem],
                        initialProviders: [IdentifyPreviewFixtures.provider]))
            }
        }

        #Preview("Review · Empty") {
            NavigationStack {
                IdentifyReviewView(
                    session: .init(service: AdministrativePreviewService(), browser: IdentifyPreviewEntityBrowser()))
            }
        }
    #endif
#endif
