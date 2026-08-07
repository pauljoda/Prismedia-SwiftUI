import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestReviewView: View {
        @Environment(\.artworkPrimaryAccent) private var inheritedPrimaryAccent
        let service: any RequestFeatureServicing
        let route: RequestReviewRoute
        let hidesNsfw: Bool
        @Binding var flowPhase: RequestIdentifyFlowPhase
        let onNavigateToEntity: (RequestEntityNavigationIntent) -> Void

        @State private var review: AdministrativeRequestReviewResponse?
        @State private var selectedIDs: Set<String> = []
        @State private var chosenPreset = RequestMonitorPreset.all
        @State private var isCustomSelection = false
        @State private var reviewSelection = MetadataReviewSelection()
        @State private var proposalPath: [AdministrativeEntityMetadataProposal] = []
        @State private var roots: [AdministrativeLibraryRoot] = []
        @State private var profiles: [AdministrativeAcquisitionProfile] = []
        @State private var selectedProfileID: UUID?
        @State private var selectedRootID: UUID?
        @State private var isLoading = true
        @State private var isLoadingTargets = true
        @State private var isSubmitting = false
        @State private var requiresReload = false
        @State private var errorMessage: String?
        @State private var targetErrorMessage: String?
        @State private var loadRevision = RequestLoadRevision()
        @State private var outcome: RequestCommitResult?
        @State private var artworkPalette: ArtworkPalette?

        var body: some View {
            Group {
                if isLoading {
                    loadingView
                } else {
                    ScrollView {
                        Group {
                            if let review {
                                reviewContent(review)
                            } else {
                                errorView
                            }
                        }
                        .padding()
                    }
                }
            }
            .prismediaScreenBackground(palette: artworkPalette)
            .navigationTitle("Review Request")
            .environment(\.artworkPalette, artworkPalette)
            .environment(\.artworkPrimaryAccent, primaryAccent)
            .prismediaArtworkPalette(
                for: reviewArtworkPath,
                palette: $artworkPalette
            )
            .task { await loadReview() }
            .alert(
                outcome?.title ?? "Request",
                isPresented: Binding(get: { outcome != nil }, set: { if !$0 { outcome = nil } })
            ) {
                if let intent = outcome?.navigationIntent {
                    Button("View") { onNavigateToEntity(intent) }
                }
                Button("Done", role: .cancel) {}
            } message: {
                Text(outcome?.message ?? "")
            }
            .accessibilityIdentifier("request.review")
        }

        private var loadingView: some View {
            PrismediaLoadingView("Building the canonical proposal…")
        }

        private var errorView: some View {
            ContentUnavailableView {
                Label("Review Unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage ?? "The proposal could not be loaded.")
            } actions: {
                Button("Try Again", systemImage: "arrow.clockwise") {
                    Task { await loadReview() }
                }
            }
        }

        private func reviewContent(_ review: AdministrativeRequestReviewResponse) -> some View {
            let selection = RequestSelectionPolicy.derive(from: review)
            let activeProposal = proposalPath.last ?? review.proposal
            let structuralIDs = Set(
                MetadataReviewPolicy.structuralChildren(of: activeProposal).map(\.proposalID)
            )
            let relationshipIDs = Set(
                MetadataReviewPolicy.relationships(of: activeProposal).map(\.proposalID)
            )
            let selectableReviewIDs = structuralIDs.union(relationshipIDs)
            let selectedReviewIDs = selectableReviewIDs.subtracting(reviewSelection.excludedProposalIDs)
            let activeChildrenTitle = MetadataReviewPolicy.structuralChildren(of: activeProposal)
                .first?.targetKind.groupLabel ?? childrenTitle
            return VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                if requiresReload {
                    conflictBanner
                }

                requestPanel(selection)

                if proposalPath.count > 1 {
                    Button("Back", systemImage: "chevron.left") {
                        proposalPath.removeLast()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Back to previous proposal")
                }

                MetadataProposalReviewView(
                    proposal: activeProposal,
                    headerSubtitle: "\(route.externalIdentity.namespace):\(route.externalIdentity.value)",
                    selection: $reviewSelection,
                    selectedProposalIDs: selectedReviewIDs,
                    selectableProposalIDs: selectableReviewIDs,
                    childrenTitle: activeChildrenTitle,
                    onSetProposalSelected: setProposalSelected,
                    onActivateProposal: openProposal
                )

                requestPanel(selection)
            }
        }

        private func requestPanel(_ selection: RequestReviewSelection) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                Label(requestPanelTitle(selection), systemImage: "paperplane")
                    .font(.headline)

                if selection.mode == .directChildren {
                    presetControls(selection)
                }

                RequestTargetOptionsView(
                    kind: route.kind,
                    roots: roots,
                    profiles: profiles,
                    isLoading: isLoadingTargets,
                    errorMessage: targetErrorMessage,
                    selectedProfileID: $selectedProfileID,
                    selectedRootID: $selectedRootID,
                    embedsInParentPanel: true
                )

                if let errorMessage, !requiresReload {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(PrismediaColor.destructive)
                }

                PrismediaButton(
                    isSubmitting ? "Requesting…" : requestButtonTitle(selection),
                    systemImage: "paperplane",
                    variant: .prominent,
                    form: .fill,
                    primaryTint: primaryAccent,
                    isLoading: isSubmitting,
                    action: commit
                )
                .disabled(isSubmitting || requiresReload || !hasRequestIntent(selection))
                .accessibilityIdentifier("request.commit")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
        }

        private func requestPanelTitle(_ selection: RequestReviewSelection) -> String {
            guard selection.mode == .directChildren, let noun = route.kind.childNoun else {
                return "Request This \(route.kind.label)"
            }
            return "Request \(noun.capitalized)s"
        }

        private var conflictBanner: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Label("Proposal Changed", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                Text(
                    "The provider changed this proposal after you reviewed it. Reload and confirm the selection again."
                )
                .font(.callout)
                .foregroundStyle(PrismediaColor.textSecondary)
                PrismediaButton(
                    "Reload Review",
                    systemImage: "arrow.clockwise",
                    variant: .prominent,
                    primaryTint: primaryAccent
                ) {
                    Task { await loadReview() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
        }

        private func presetControls(_ selection: RequestReviewSelection) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                LabeledContent {
                    Picker("Monitor", selection: presetBinding(selection)) {
                        ForEach(RequestMonitorPreset.allCases.filter { $0 != .custom || isCustomSelection }) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                } label: {
                    Label("Monitor", systemImage: "dot.radiowaves.left.and.right")
                }
                Text((isCustomSelection ? RequestMonitorPreset.custom : chosenPreset).detail)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
            }
        }

        private func presetBinding(_ selection: RequestReviewSelection) -> Binding<RequestMonitorPreset> {
            Binding(
                get: { isCustomSelection ? .custom : chosenPreset },
                set: { preset in
                    guard preset != .custom else { return }
                    chosenPreset = preset
                    isCustomSelection = false
                    setSelectedChildren(
                        RequestPresetPolicy.selectedIDs(for: preset, children: selection.children),
                        selection: selection
                    )
                }
            )
        }

        private var childrenTitle: String {
            guard let noun = route.kind.childNoun else { return "Items" }
            return noun.capitalized + "s"
        }

        private var reviewArtworkPath: String? {
            guard let review else { return route.artworkPath }
            return MetadataReviewArtworkPolicy.primaryArtworkPath(
                for: review.proposal,
                fallback: route.artworkPath
            )
        }

        private var primaryAccent: Color {
            artworkPalette?.primary.color ?? inheritedPrimaryAccent
        }

        @MainActor
        private func loadReview() async {
            let revision = loadRevision.advance()
            isLoading = true
            isLoadingTargets = true
            flowPhase = .reviewLoading
            errorMessage = nil
            targetErrorMessage = nil
            requiresReload = false
            async let loadedReview = service.review(
                kind: route.kind.rawValue,
                pluginID: route.pluginID,
                externalIdentity: route.externalIdentity
            )
            async let loadedRoots = service.libraryRoots()
            async let loadedProfiles = service.acquisitionProfiles()

            do {
                let nextReview = try await loadedReview
                guard loadRevision.isCurrent(revision) else { return }
                review = nextReview
                let selection = RequestSelectionPolicy.derive(from: nextReview)
                reviewSelection = MetadataReviewPolicy.seededSelection(for: nextReview.proposal)
                proposalPath = [nextReview.proposal]
                chosenPreset = .all
                isCustomSelection = false
                let initialIDs =
                    selection.mode == .directChildren
                    ? RequestPresetPolicy.selectedIDs(for: .all, children: selection.children)
                    : selection.rootSelection
                setSelectedChildren(initialIDs, selection: selection)
                isLoading = false
            } catch {
                guard loadRevision.isCurrent(revision) else { return }
                review = nil
                errorMessage = error.localizedDescription
                isLoading = false
                flowPhase = .reviewError
            }

            do {
                let (allRoots, allProfiles) = try await (loadedRoots, loadedProfiles)
                guard loadRevision.isCurrent(revision) else { return }
                roots = RequestTargetPolicy.roots(for: route.kind, from: allRoots, hidesNsfw: hidesNsfw)
                profiles = RequestTargetPolicy.profiles(for: route.kind, from: allProfiles)
                let defaultProfile = RequestTargetPolicy.defaultProfile(for: route.kind, from: profiles)
                selectedProfileID = defaultProfile?.id
                selectedRootID = RequestTargetPolicy.defaultRootID(for: defaultProfile, compatibleRoots: roots)
            } catch {
                guard loadRevision.isCurrent(revision) else { return }
                targetErrorMessage = "Request options could not be loaded: \(error.localizedDescription)"
            }
            if loadRevision.isCurrent(revision) { isLoadingTargets = false }
            if loadRevision.isCurrent(revision), review != nil {
                flowPhase = .reviewReady
            }
        }

        private func toggleProposal(_ proposalID: String, _ selected: Bool) {
            guard let review else { return }
            let selection = RequestSelectionPolicy.derive(from: review)
            guard selection.selectableIDs.contains(proposalID) else { return }
            if selected { selectedIDs.insert(proposalID) } else { selectedIDs.remove(proposalID) }
            MetadataReviewPolicy.setProposal(
                proposalID,
                selected: selected,
                within: review.proposal,
                selection: &reviewSelection
            )
            isCustomSelection = true
        }

        private func setSelectedChildren(
            _ ids: Set<String>,
            selection: RequestReviewSelection
        ) {
            selectedIDs = ids
            guard let review else { return }
            for proposalID in selection.selectableIDs {
                MetadataReviewPolicy.setProposal(
                    proposalID,
                    selected: ids.contains(proposalID),
                    within: review.proposal,
                    selection: &reviewSelection
                )
            }
        }

        private func setProposalSelected(_ proposalID: String, _ selected: Bool) {
            guard let review else { return }
            let requestSelection = RequestSelectionPolicy.derive(from: review)
            if requestSelection.selectableIDs.contains(proposalID) {
                toggleProposal(proposalID, selected)
                return
            }
            MetadataReviewPolicy.setProposal(
                proposalID,
                selected: selected,
                within: review.proposal,
                selection: &reviewSelection
            )
        }

        private func openProposal(_ proposal: AdministrativeEntityMetadataProposal) {
            guard !proposalPath.contains(where: { $0.proposalID == proposal.proposalID }) else { return }
            proposalPath.append(proposal)
        }

        private func hasRequestIntent(_ selection: RequestReviewSelection) -> Bool {
            if selection.mode == .root { return !selection.rootSelection.isEmpty }
            return !selectedIDs.isEmpty || !isCustomSelection
        }

        private func requestButtonTitle(_ selection: RequestReviewSelection) -> String {
            guard selection.mode == .directChildren else { return "Request \(route.kind.label)" }
            if selectedIDs.isEmpty { return "Apply \(chosenPreset.label)" }
            return "Request \(selectedIDs.count) \(route.kind.childNoun ?? "item")\(selectedIDs.count == 1 ? "" : "s")"
        }

        private func commit() {
            guard let review else { return }
            let selection = RequestSelectionPolicy.derive(from: review)
            let ids =
                selection.mode == .directChildren
                ? selectedIDs.intersection(selection.selectableIDs).sorted()
                : selection.rootSelection.sorted()
            guard hasRequestIntent(selection) else { return }
            let selectedProposal = MetadataReviewPolicy.proposalForApply(
                review.proposal,
                selection: reviewSelection
            )
            isSubmitting = true
            flowPhase = .committing
            errorMessage = nil
            let request = AdministrativeReviewedRequestCommitRequest(
                kind: review.kind,
                pluginID: review.pluginID,
                rootExternalIdentity: review.externalIdentity,
                proposalRevision: review.revision,
                selectedProposalIDs: ids,
                targetLibraryRootID: selectedRootID,
                profileID: selectedProfileID,
                preset: selection.mode == .directChildren ? chosenPreset.wireValue : nil,
                review: review,
                proposal: selectedProposal,
                selectedFields: MetadataReviewPolicy.selectedRootFields(
                    for: review.proposal,
                    selection: reviewSelection
                ),
                selectedImages: MetadataReviewPolicy.selectedRootImages(
                    for: review.proposal,
                    selection: reviewSelection
                )
            )
            Task {
                do {
                    let response = try await service.commit(request)
                    let result = RequestCommitOutcomePolicy.resolve(response: response, review: review)
                    isSubmitting = false
                    flowPhase = .success
                    if let intent = result.navigationIntent {
                        onNavigateToEntity(intent)
                    } else {
                        outcome = result
                    }
                } catch let PrismediaAPIError.httpStatus(_, problem)
                    where problem?.code == "request_proposal_changed"
                {
                    requiresReload = true
                    errorMessage = "This proposal changed after you reviewed it."
                    isSubmitting = false
                    flowPhase = .commitFailure
                } catch {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                    flowPhase = .commitFailure
                }
            }
        }
    }

    #if DEBUG
        #Preview("Request Review") {
            NavigationStack {
                RequestReviewView(
                    service: RequestPreviewService(scenario: .content),
                    route: RequestPreviewFixtures.route,
                    hidesNsfw: true,
                    flowPhase: .constant(.reviewReady),
                    onNavigateToEntity: { _ in }
                )
            }
        }
    #endif
#endif
