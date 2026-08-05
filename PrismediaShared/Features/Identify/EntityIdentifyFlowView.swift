import SwiftUI

#if os(iOS) || os(macOS)
    struct EntityIdentifyFlowView: View {
        @Environment(\.dismiss) private var dismiss
        @Bindable var session: IdentifySession
        let entityID: UUID
        let automaticallyBegins: Bool
        let onIdentified: @MainActor () async -> Void

        @State private var path: [RequestIdentifyFlowRoute] = []
        @State private var isFinishing = false

        init(
            session: IdentifySession,
            entityID: UUID,
            automaticallyBegins: Bool = true,
            onIdentified: @escaping @MainActor () async -> Void
        ) {
            self.session = session
            self.entityID = entityID
            self.automaticallyBegins = automaticallyBegins
            self.onIdentified = onIdentified
        }

        var body: some View {
            RequestIdentifyFlowSheet(
                mode: .identify,
                phase: phase,
                path: $path
            ) {
                rootContent
                    .navigationTitle("Identify")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .navigationDestination(for: RequestIdentifyFlowRoute.self) { route in
                        destination(for: route)
                    }
            }
            .task {
                if automaticallyBegins {
                    await session.beginEntry(entityID: entityID)
                }
                await observeQueuedWork()
            }
            .onChange(of: shouldPresentReview, initial: true) { _, shouldPresent in
                guard shouldPresent, path.last != .identifyReview else { return }
                path.append(.identifyReview)
            }
            .onChange(of: session.showsSearchForProposal) {
                guard session.showsSearchForProposal else { return }
                path.removeAll()
            }
            .onDisappear {
                session.cancelPolling()
            }
        }

        @ViewBuilder
        private var rootContent: some View {
            if let item = session.selectedItem {
                IdentifySearchView(session: session, item: item)
            } else if let errorMessage = session.errorMessage {
                ContentUnavailableView {
                    Label("Identify Unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again", systemImage: "arrow.clockwise") {
                        Task { await session.beginEntry(entityID: entityID) }
                    }
                }
            } else {
                PrismediaLoadingView("Preparing identify search…")
            }
        }

        @ViewBuilder
        private func destination(
            for route: RequestIdentifyFlowRoute
        ) -> some View {
            switch route {
            case .identifyReview:
                if let item = session.selectedItem,
                    let proposal = item.proposal
                {
                    IdentifyProposalReviewPage(
                        session: session,
                        item: item,
                        proposal: proposal,
                        isRoot: true,
                        onApplied: finishIdentification,
                        onRejected: dismiss.callAsFunction
                    )
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Search", systemImage: "chevron.left") {
                                session.returnToSearch()
                                path.removeLast()
                            }
                            .prismediaToolbarActionLabelStyle()
                            .disabled(phase.locksDismissal)
                            .accessibilityHint("Returns to the preserved identify search")
                        }

                        ToolbarItem(placement: closePlacement) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .disabled(phase.locksDismissal)
                            .accessibilityLabel("Close Identify")
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Review Unavailable",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Return to Search and choose a metadata match.")
                    )
                }
            }
        }

        private var phase: RequestIdentifyFlowPhase {
            if isFinishing || session.isApplying {
                return .committing
            }
            if session.isLoading && session.selectedItem == nil {
                return .initialDependencyLoading
            }
            guard let item = session.selectedItem else {
                return session.errorMessage == nil ? .initialDependencyLoading : .reviewError
            }
            if session.isSearchBusy {
                return .searching
            }
            if session.errorMessage != nil {
                return path.last == .identifyReview ? .commitFailure : .searchError
            }

            switch IdentifyQueueState(rawServerValue: item.state) {
            case .queued, .searching:
                return .searching
            case .choice:
                return item.candidates.isEmpty ? .empty : .results
            case .proposal:
                return path.last == .identifyReview ? .reviewReady : .selection
            case .applying:
                return .committing
            case .done, .deleted:
                return .success
            case .error:
                return .searchError
            case .unknown(let value):
                return .unknown(value)
            }
        }

        private var shouldPresentReview: Bool {
            guard let item = session.selectedItem else { return false }
            return IdentifyReviewRoutingPolicy.shouldPresentReview(
                queueState: IdentifyQueueState(rawServerValue: item.state),
                hasProposal: item.proposal != nil,
                explicitlyShowsSearch: session.showsSearchForProposal,
                isSearching: session.isSearching
                    || session.isLoadingMore
                    || session.isRescanning
                    || session.isResolving,
                isSeeking: session.isSeeking
            )
        }

        @MainActor
        private func finishIdentification() async {
            isFinishing = true
            await onIdentified()
            isFinishing = false
            dismiss()
        }

        private var closePlacement: ToolbarItemPlacement {
            #if os(iOS)
                .topBarTrailing
            #else
                .confirmationAction
            #endif
        }

        @MainActor
        private func observeQueuedWork() async {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }

                guard let item = session.selectedItem else { continue }
                let state = IdentifyQueueState(rawServerValue: item.state)
                guard state == .queued || state == .searching || state == .applying else {
                    return
                }
                guard !session.isSearchBusy, !session.isApplying else { continue }
                await session.refreshSelectedItem()
            }
        }
    }

    #if DEBUG
        #Preview("Entity Identify Flow") {
            EntityIdentifyFlowView(
                session: IdentifySession(
                    service: AdministrativePreviewService(),
                    browser: IdentifyPreviewEntityBrowser(),
                    initialQueue: [IdentifyPreviewFixtures.reviewItem],
                    initialProviders: [IdentifyPreviewFixtures.provider]
                ),
                entityID: IdentifyPreviewFixtures.reviewItem.entityID,
                automaticallyBegins: false,
                onIdentified: {}
            )
        }
    #endif
#endif
