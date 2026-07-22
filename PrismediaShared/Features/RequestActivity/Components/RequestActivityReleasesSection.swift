import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityReleasesSection: View {
        @State private var visibleCount = 10
        @State private var sort = RequestActivityReleaseSort.bestMatch
        @State private var showsOnlyRelevant = true
        @State private var usesDenseLayout = false
        @State private var candidatePendingBlocklist: RequestActivityReleaseCandidate?

        let candidates: [RequestActivityReleaseCandidate]
        let canPickRelease: Bool
        let isLoading: Bool
        let isBusy: Bool
        let activeAction: RequestActivityCandidateAction?
        let showsTorrentFallback: Bool
        let onDownload: (RequestActivityReleaseCandidate) -> Void
        let onBlocklist: (RequestActivityReleaseCandidate) -> Void
        let onUploadTorrent: () -> Void

        init(
            candidates: [RequestActivityReleaseCandidate],
            canPickRelease: Bool,
            isLoading: Bool = false,
            isBusy: Bool,
            activeAction: RequestActivityCandidateAction? = nil,
            showsTorrentFallback: Bool = true,
            onDownload: @escaping (RequestActivityReleaseCandidate) -> Void,
            onBlocklist: @escaping (RequestActivityReleaseCandidate) -> Void,
            onUploadTorrent: @escaping () -> Void
        ) {
            self.candidates = candidates
            self.canPickRelease = canPickRelease
            self.isLoading = isLoading
            self.isBusy = isBusy
            self.activeAction = activeAction
            self.showsTorrentFallback = showsTorrentFallback
            self.onDownload = onDownload
            self.onBlocklist = onBlocklist
            self.onUploadTorrent = onUploadTorrent
        }

        #if DEBUG
            init(
                previewCandidates candidates: [RequestActivityReleaseCandidate],
                canPickRelease: Bool = true,
                isLoading: Bool = false,
                isBusy: Bool = false,
                activeAction: RequestActivityCandidateAction? = nil,
                showsOnlyRelevant: Bool = true,
                sort: RequestActivityReleaseSort = .bestMatch,
                usesDenseLayout: Bool = false,
                candidatePendingBlocklist: RequestActivityReleaseCandidate? = nil
            ) {
                self.init(
                    candidates: candidates,
                    canPickRelease: canPickRelease,
                    isLoading: isLoading,
                    isBusy: isBusy,
                    activeAction: activeAction,
                    showsTorrentFallback: false,
                    onDownload: { _ in },
                    onBlocklist: { _ in },
                    onUploadTorrent: {}
                )
                _showsOnlyRelevant = State(initialValue: showsOnlyRelevant)
                _sort = State(initialValue: sort)
                _usesDenseLayout = State(initialValue: usesDenseLayout)
                _candidatePendingBlocklist = State(initialValue: candidatePendingBlocklist)
            }
        #endif

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                header
                if !candidates.isEmpty { controls }
                candidateContent
                if canPickRelease && showsTorrentFallback { torrentUploadFallback }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: Bool.self) { proxy in
                proxy.size.width >= 700
            } action: {
                usesDenseLayout = $0
            }
            .onChange(of: candidates) {
                visibleCount = pageSize
            }
            .onChange(of: sort) {
                visibleCount = pageSize
            }
            .onChange(of: showsOnlyRelevant) {
                visibleCount = pageSize
            }
            .confirmationDialog(
                "Block this release?",
                isPresented: blocklistConfirmationIsPresented,
                titleVisibility: .visible
            ) {
                Button("Blocklist Release", role: .destructive) { confirmBlocklist() }
                Button("Cancel", role: .cancel) { candidatePendingBlocklist = nil }
            } message: {
                if let candidatePendingBlocklist {
                    Text(
                        "\(RequestActivityReleasePolicy.displayTitle(for: candidatePendingBlocklist)) will not be downloaded now or offered by future searches. You can allow it again from Blocklist settings."
                    )
                }
            }
        }

        private var header: some View {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                    headerTitle
                    headerCount
                }
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    headerTitle
                    headerCount
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }

        private var headerTitle: some View {
            Text("Release Candidates")
                .font(.headline)
                .foregroundStyle(PrismediaColor.textPrimary)
        }

        private var headerCount: some View {
            Text("\(eligibleCount) eligible · \(candidates.count) total")
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)
        }

        private var controls: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                relevanceToggle
                    .frame(maxWidth: .infinity)
                if !usesDenseLayout {
                    HStack {
                        Spacer(minLength: 0)
                        sortMenu
                    }
                }
            }
        }

        @ViewBuilder
        private var relevanceToggle: some View {
            if rejectedCount > 0 {
                Toggle(isOn: $showsOnlyRelevant) {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text("Show Only Relevant")
                        if hiddenCount > 0 {
                            Text("\(hiddenCount) hidden")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(PrismediaColor.textMuted)
                        }
                    }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
            }
        }

        private var sortMenu: some View {
            PrismediaButton(
                "Sort releases: \(sort.title)",
                systemImage: "arrow.up.arrow.down",
                form: .compactIcon
            ) {
                ForEach(RequestActivityReleaseSort.allCases, id: \.self) { option in
                    Button {
                        sort = option
                    } label: {
                        if sort == option {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            }
            .prismediaCompactActionControlSize()
        }

        @ViewBuilder
        private var candidateContent: some View {
            if isLoading {
                PrismediaLoadingView("Loading release candidates…")
                    .frame(minHeight: 240)
            } else if candidates.isEmpty {
                RequestActivityStatePlaceholder(
                    title: "No Releases Found",
                    message: "No indexer returned a matching release for this title.",
                    systemImage: "magnifyingglass"
                )
            } else if visibleCandidates.isEmpty {
                RequestActivityStatePlaceholder(
                    title: "All Releases Are Blocked",
                    message: "Turn off Show Only Relevant to review blocked results.",
                    systemImage: "hand.raised"
                )
            } else if usesDenseLayout {
                denseCandidates
            } else {
                cardCandidates
            }
        }

        private var cardCandidates: some View {
            LazyVStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                ForEach(visibleCandidates) { candidate in
                    candidateRow(candidate, layout: .card)
                }
                if remainingCount > 0 { loadMoreButton }
            }
        }

        private var denseCandidates: some View {
            VStack(spacing: 0) {
                Grid(alignment: .leading, horizontalSpacing: PrismediaSpacing.medium) {
                    denseHeader
                    Divider().gridCellColumns(6)
                    ForEach(visibleCandidates) { candidate in
                        candidateRow(candidate, layout: .dense)
                    }
                }
                if remainingCount > 0 {
                    Divider()
                    loadMoreButton
                        .padding(PrismediaSpacing.medium)
                }
            }
            .padding(.horizontal, PrismediaSpacing.medium)
            .prismediaPanel()
        }

        private var denseHeader: some View {
            GridRow {
                sortHeader("Release", ascending: .titleAscending, descending: .titleDescending)
                    .gridColumnAlignment(.leading)
                sortHeader("Indexer", ascending: .indexerAscending, descending: .indexerDescending)
                    .gridColumnAlignment(.leading)
                sortHeader("Size", ascending: .sizeAscending, descending: .sizeDescending)
                    .gridColumnAlignment(.trailing)
                sortHeader("Seeders", ascending: .seedersAscending, descending: .seedersDescending)
                    .gridColumnAlignment(.trailing)
                Button {
                    sort = .bestMatch
                } label: {
                    HStack(spacing: PrismediaSpacing.extraSmall) {
                        Text("Score")
                        if sort == .bestMatch {
                            Image(systemName: "chevron.down")
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sort by best match")
                .gridColumnAlignment(.trailing)
                Text("Actions")
                    .gridColumnAlignment(.trailing)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(PrismediaColor.textMuted)
            .textCase(.uppercase)
            .padding(.vertical, PrismediaSpacing.small)
        }

        private func sortHeader(
            _ title: String,
            ascending: RequestActivityReleaseSort,
            descending: RequestActivityReleaseSort
        ) -> some View {
            Button {
                sort = sort == descending ? ascending : descending
            } label: {
                HStack(spacing: PrismediaSpacing.extraSmall) {
                    Text(title)
                    Image(
                        systemName: sort == ascending
                            ? "chevron.up" : sort == descending ? "chevron.down" : "chevron.up.chevron.down"
                    )
                    .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sort by \(title)")
        }

        private func candidateRow(
            _ candidate: RequestActivityReleaseCandidate,
            layout: RequestActivityCandidateLayout
        ) -> some View {
            RequestActivityCandidateRow(
                candidate: candidate,
                layout: layout,
                isDisabled: isBusy || !canPickRelease,
                activeAction: activeAction,
                onDownload: onDownload,
                onRequestBlocklist: { candidatePendingBlocklist = $0 }
            )
        }

        private var loadMoreButton: some View {
            PrismediaButton(
                "Load \(nextPageCount) More Releases",
                systemImage: "chevron.down",
                form: .fill
            ) {
                visibleCount += pageSize
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
            .padding(.vertical, PrismediaSpacing.small)
        }

        private var torrentUploadFallback: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text("Have a .torrent file?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(
                        "Open a release page above, download its .torrent, then upload it here to download directly."
                    )
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
                }

                PrismediaButton(
                    "Upload .torrent",
                    systemImage: "doc.badge.plus",
                    form: .fill
                ) {
                    onUploadTorrent()
                }
                .frame(maxWidth: .infinity)
                .prismediaCompactActionControlSize()
                .disabled(isBusy)
            }
            .padding(PrismediaSpacing.medium)
            .prismediaPanel()
        }

        private var filteredCandidates: [RequestActivityReleaseCandidate] {
            RequestActivityReleasePolicy.filteredCandidates(
                candidates,
                showsOnlyRelevant: showsOnlyRelevant
            )
        }

        private var sortedCandidates: [RequestActivityReleaseCandidate] {
            RequestActivityReleasePolicy.sortedCandidates(filteredCandidates, by: sort)
        }

        private var visibleCandidates: ArraySlice<RequestActivityReleaseCandidate> {
            sortedCandidates.prefix(visibleCount)
        }

        private var eligibleCount: Int {
            candidates.count { RequestActivityReleasePolicy.disposition(of: $0) == .eligible }
        }

        private var rejectedCount: Int { candidates.count - eligibleCount }
        private var hiddenCount: Int { candidates.count - filteredCandidates.count }
        private var remainingCount: Int { max(0, sortedCandidates.count - visibleCount) }
        private var nextPageCount: Int { min(pageSize, remainingCount) }
        private var pageSize: Int { 10 }
        private var blocklistConfirmationIsPresented: Binding<Bool> {
            Binding(
                get: { candidatePendingBlocklist != nil },
                set: { if !$0 { candidatePendingBlocklist = nil } }
            )
        }

        private func confirmBlocklist() {
            guard let candidatePendingBlocklist else { return }
            self.candidatePendingBlocklist = nil
            onBlocklist(candidatePendingBlocklist)
        }
    }

    #if DEBUG
        #Preview("Releases Section") {
            ScrollView {
                RequestActivityReleasesSection(
                    previewCandidates: [
                        RequestActivityPreviewFixtures.candidate,
                        RequestActivityPreviewFixtures.rejectedCandidate,
                    ]
                )
                .padding()
            }
            .background(PrismediaBackdrop())
            .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
            .preferredColorScheme(.dark)
        }
    #endif
#endif
