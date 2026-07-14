import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyReviewView: View {
        @Bindable var session: IdentifySession

        var body: some View {
            if let item = session.selectedItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                        header(item)
                        if let proposal = item.proposal, !session.showsSearchForProposal {
                            MetadataProposalReviewView(proposal: proposal, selection: $session.reviewSelection)
                            applyActions(item)
                        } else {
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
                                isSeeking: session.isSeeking)
                        }
                    }.padding()
                }
                .navigationTitle("Review")
                .toolbar { reviewNavigation }
                .accessibilityIdentifier("identify.review")
            } else {
                ContentUnavailableView(
                    "Choose an Item", systemImage: "checklist",
                    description: Text("Select an identify queue item to search or review metadata."))
            }
        }

        private func header(_ item: AdministrativeIdentifyQueueItem) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(item.title).font(.title2.bold())
                Text("\(item.entityKind.displayLabel) · \(IdentifyQueueState(rawServerValue: item.state).label)")
                    .foregroundStyle(PrismediaColor.textSecondary)
                if item.cascadeRunning {
                    Label("Applying related metadata", systemImage: "arrow.triangle.branch").foregroundStyle(
                        PrismediaColor.warning)
                }
            }
        }

        private func applyActions(_ item: AdministrativeIdentifyQueueItem) -> some View {
            VStack(spacing: PrismediaSpacing.medium) {
                if let progress = session.applyProgress {
                    ProgressView(value: Double(progress.currentIndex), total: Double(max(progress.total, 1))) {
                        Text(progress.currentTitle ?? "Applying metadata")
                    }
                }
                ViewThatFits {
                    HStack { actionButtons(item) }
                    VStack { actionButtons(item) }
                }
            }.padding(PrismediaSpacing.large).prismediaPanel()
        }

        @ViewBuilder private func actionButtons(_ item: AdministrativeIdentifyQueueItem) -> some View {
            PrismediaButton(
                "Back to Search",
                systemImage: "arrow.left",
                action: session.returnToSearch
            )
            PrismediaButton(
                "Reject",
                systemImage: "xmark",
                variant: .destructive
            ) {
                Task { await session.reject(advance: false) }
            }
            PrismediaButton(
                "Reject & Next",
                systemImage: "xmark",
                variant: .destructive
            ) {
                Task { await session.reject(advance: true) }
            }
            PrismediaButton(
                "Accept",
                systemImage: "checkmark",
                variant: .prominent
            ) {
                Task { await session.apply(advance: false) }
            }
            .disabled(session.isApplying || item.cascadeRunning)
            PrismediaButton(
                "Accept & Next",
                systemImage: "checkmark",
                variant: .prominent
            ) {
                Task { await session.apply(advance: true) }
            }
            .disabled(session.isApplying || item.cascadeRunning)
        }

        @ToolbarContentBuilder private var reviewNavigation: some ToolbarContent {
            ToolbarItemGroup {
                Button("Previous", systemImage: "chevron.left", action: session.selectPrevious).disabled(
                    session.reviewableIDs.count < 2)
                Button("Next", systemImage: "chevron.right", action: session.selectNext).disabled(
                    session.reviewableIDs.count < 2)
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
