import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestReviewView: View {
        @Environment(\.dismiss) private var dismiss

        let service: any RequestFeatureServicing
        let route: RequestReviewRoute
        let hidesNsfw: Bool
        let onNavigateToEntity: (RequestEntityNavigationIntent) -> Void

        @State private var review: AdministrativeRequestReviewResponse?
        @State private var selectedIDs: Set<String> = []
        @State private var chosenPreset = RequestMonitorPreset.missing
        @State private var isCustomSelection = false
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
            .navigationTitle("Review Request")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
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
            return VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                if requiresReload {
                    conflictBanner
                }

                MetadataProposalReviewView(
                    proposal: review.proposal,
                    selectedProposalIDs: selectedIDs,
                    selectableProposalIDs: selection.selectableIDs,
                    childrenTitle: childrenTitle,
                    onSetProposalSelected: toggleProposal
                )

                if selection.mode == .directChildren {
                    presetPanel(selection)
                }

                RequestTargetOptionsView(
                    kind: route.kind,
                    roots: roots,
                    profiles: profiles,
                    isLoading: isLoadingTargets,
                    errorMessage: targetErrorMessage,
                    selectedProfileID: $selectedProfileID,
                    selectedRootID: $selectedRootID
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
                    isLoading: isSubmitting,
                    action: commit
                )
                .disabled(isSubmitting || requiresReload || !hasRequestIntent(selection))
                .accessibilityIdentifier("request.commit")
            }
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
                    variant: .prominent
                ) {
                    Task { await loadReview() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
        }

        private func presetPanel(_ selection: RequestReviewSelection) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Label("Monitoring", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                Picker("Preset", selection: presetBinding(selection)) {
                    ForEach(RequestMonitorPreset.allCases.filter { $0 != .custom || isCustomSelection }) { preset in
                        Text(preset.label).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                Text((isCustomSelection ? RequestMonitorPreset.custom : chosenPreset).detail)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.large)
            .prismediaPanel()
        }

        private func presetBinding(_ selection: RequestReviewSelection) -> Binding<RequestMonitorPreset> {
            Binding(
                get: { isCustomSelection ? .custom : chosenPreset },
                set: { preset in
                    guard preset != .custom else { return }
                    chosenPreset = preset
                    isCustomSelection = false
                    selectedIDs = RequestPresetPolicy.selectedIDs(for: preset, children: selection.children)
                }
            )
        }

        private var childrenTitle: String {
            guard let noun = route.kind.childNoun else { return "Items" }
            return noun.capitalized + "s"
        }

        @MainActor
        private func loadReview() async {
            let revision = loadRevision.advance()
            isLoading = true
            isLoadingTargets = true
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
                chosenPreset = .missing
                isCustomSelection = false
                selectedIDs =
                    selection.mode == .directChildren
                    ? RequestPresetPolicy.selectedIDs(for: .missing, children: selection.children)
                    : selection.rootSelection
                isLoading = false
            } catch {
                guard loadRevision.isCurrent(revision) else { return }
                review = nil
                errorMessage = error.localizedDescription
                isLoading = false
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
        }

        private func toggleProposal(_ proposalID: String, _ selected: Bool) {
            guard let review else { return }
            let selection = RequestSelectionPolicy.derive(from: review)
            guard selection.selectableIDs.contains(proposalID) else { return }
            if selected { selectedIDs.insert(proposalID) } else { selectedIDs.remove(proposalID) }
            isCustomSelection = true
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
            isSubmitting = true
            errorMessage = nil
            let request = AdministrativeReviewedRequestCommitRequest(
                kind: review.kind,
                pluginID: review.pluginID,
                rootExternalIdentity: review.externalIdentity,
                proposalRevision: review.revision,
                selectedProposalIDs: ids,
                targetLibraryRootID: selectedRootID,
                profileID: selectedProfileID,
                preset: selection.mode == .directChildren ? chosenPreset.wireValue : nil
            )
            Task {
                do {
                    let response = try await service.commit(request)
                    outcome = RequestCommitOutcomePolicy.resolve(response: response, review: review)
                } catch let PrismediaAPIError.httpStatus(_, problem)
                    where problem?.code == "request_proposal_changed"
                {
                    requiresReload = true
                    errorMessage = "This proposal changed after you reviewed it."
                } catch {
                    errorMessage = error.localizedDescription
                }
                isSubmitting = false
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
                    onNavigateToEntity: { _ in }
                )
            }
        }
    #endif
#endif
