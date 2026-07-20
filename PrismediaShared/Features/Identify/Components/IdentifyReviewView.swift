import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyReviewView: View {
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @Bindable var session: IdentifySession

        var body: some View {
            if let item = session.selectedItem {
                Group {
                    if let proposal = item.proposal, !session.showsSearchForProposal {
                        IdentifyProposalReviewPage(
                            session: session,
                            item: item,
                            proposal: proposal,
                            isRoot: true
                        )
                    } else {
                        searchSurface(item)
                    }
                }
                .navigationTitle(item.title)
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar { reviewNavigation }
                .task(id: searchRefreshTaskID) {
                    guard searchRefreshIsActive else { return }
                    await session.refreshSelectedItem()
                    await pollSearchItemWhileVisible()
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

        private var searchRefreshIsActive: Bool {
            pageIsActive
                && scenePhase == .active
                && session.selectedItemID != nil
                && (session.selectedItem?.proposal == nil || session.showsSearchForProposal)
                && !session.isSearching
                && !session.isSeeking
        }

        private var searchRefreshTaskID: String {
            "\(session.selectedItemID?.uuidString ?? "none"):\(searchRefreshIsActive)"
        }

        private func pollSearchItemWhileVisible() async {
            while searchRefreshIsActive {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                guard !Task.isCancelled, searchRefreshIsActive else { return }
                await session.refreshSelectedItem()
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
