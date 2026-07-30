import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyDashboardView: View {
        @Bindable var session: IdentifySession

        let onOpenKind: (EntityKind) -> Void
        let onReviewItem: (AdministrativeIdentifyQueueItem) -> Void
        let onReviewAll: () -> Void

        var body: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                    browseSection
                    queueSection

                    if let progress = session.bulkProgress, progress.total > 0 {
                        ProgressView(value: progress.fraction) {
                            Text("Processed \(progress.completed) of \(progress.total)")
                        }
                        .padding(PrismediaSpacing.large)
                        .prismediaPanel()
                    }
                }
                .padding(PrismediaSpacing.extraExtraLarge)
            }
            .overlay {
                if session.isLoading && session.queue.isEmpty && session.kindSummaries.isEmpty {
                    PrismediaLoadingView("Loading identify workspace…")
                }
            }
            .accessibilityIdentifier("identify.dashboard")
        }

        private var browseSection: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                sectionHeading(
                    title: "Browse by kind",
                    subtitle: "Find unorganized library items and queue them with the right metadata source."
                )

                if session.kindSummaries.isEmpty, !session.isLoading {
                    ContentUnavailableView(
                        "No Identify Providers",
                        systemImage: "puzzlepiece.extension",
                        description: Text("Enable an authenticated metadata provider to browse supported media kinds.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .prismediaPanel()
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: PrismediaSpacing.medium)],
                        alignment: .leading,
                        spacing: PrismediaSpacing.medium
                    ) {
                        ForEach(Array(session.kindSummaries.enumerated()), id: \.element.id) { index, summary in
                            kindCard(summary, accent: PrismediaColor.materialSpectrumColor(at: index + 1))
                        }
                    }
                }
            }
        }

        private var queueSection: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack(alignment: .bottom) {
                    sectionHeading(
                        title: "Review queue",
                        subtitle: "Compare provider matches before applying metadata to your library."
                    )

                    Spacer(minLength: PrismediaSpacing.large)

                    if !session.selectedQueueIDs.isEmpty {
                        Button("Accept Selected", systemImage: "checkmark") {
                            Task { await session.acceptSelected() }
                        }
                        .disabled(!session.canAcceptQueueSelection)

                        Button("Reject Selected", systemImage: "trash", role: .destructive) {
                            Task { await session.rejectSelected() }
                        }
                    }

                    Button("Review All", systemImage: "rectangle.stack", action: onReviewAll)
                        .disabled(session.reviewableIDs.isEmpty)
                }

                if session.queue.isEmpty, !session.isLoading {
                    ContentUnavailableView(
                        "Queue Is Clear",
                        systemImage: "checkmark.circle",
                        description: Text("Items needing metadata review will appear here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .prismediaPanel()
                } else {
                    queueTable
                }
            }
        }

        private var queueTable: some View {
            VStack(spacing: 0) {
                queueHeader

                Divider()

                ForEach(session.queue) { item in
                    queueRow(item)
                    if item.id != session.queue.last?.id {
                        Divider()
                    }
                }
            }
            .prismediaPanel()
            .accessibilityIdentifier("identify.dashboard-queue")
        }

        private var queueHeader: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Text("Select").frame(width: 42, alignment: .leading)
                Text("State").frame(width: 72, alignment: .leading)
                Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                Text("Provider").frame(width: 110, alignment: .leading)
                Text("Kind").frame(width: 88, alignment: .leading)
                Text("Action").frame(width: 76, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(PrismediaColor.textMuted)
            .padding(.horizontal, PrismediaSpacing.large)
            .frame(minHeight: 36)
            .background(PrismediaColor.elevatedContentBackground.opacity(0.72))
        }

        private func queueRow(_ item: AdministrativeIdentifyQueueItem) -> some View {
            let state = IdentifyQueueState(rawServerValue: item.state)

            return HStack(spacing: PrismediaSpacing.medium) {
                IdentifyQueueSelectionButton(
                    isSelected: selectionBinding(for: item.entityID),
                    title: item.title
                )
                .frame(width: 42, alignment: .leading)

                Text(state.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(stateColor(state))
                    .frame(width: 72, alignment: .leading)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text(item.proposal?.patch.title ?? item.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    if item.proposal?.patch.title != nil, item.proposal?.patch.title != item.title {
                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.provider ?? "—")
                    .lineLimit(1)
                    .frame(width: 110, alignment: .leading)

                Text(item.entityKind.displayLabel)
                    .lineLimit(1)
                    .frame(width: 88, alignment: .leading)

                Button("Review") {
                    onReviewItem(item)
                }
                .disabled(!state.isReviewable)
                .frame(width: 76, alignment: .trailing)
            }
            .font(.callout)
            .padding(.horizontal, PrismediaSpacing.large)
            .frame(minHeight: 48)
            .contentShape(.rect)
            .contextMenu {
                Button("Review", systemImage: "rectangle.and.text.magnifyingglass") {
                    onReviewItem(item)
                }
                .disabled(!state.isReviewable)
            }
        }

        private func kindCard(_ summary: IdentifyKindSummary, accent: Color) -> some View {
            Button {
                onOpenKind(summary.kind)
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    HStack {
                        Image(systemName: summary.kind.thumbnailFallbackSystemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(accent)
                        Spacer(minLength: 0)
                        if summary.pendingCount > 0 {
                            Text(summary.pendingCount, format: .number)
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                        Text(summary.kind.displayLabel)
                            .font(.headline)
                        Text(summary.kind.rawValue)
                            .font(.caption2.monospaced())
                            .foregroundStyle(PrismediaColor.textMuted)
                    }
                }
                .padding(PrismediaSpacing.large)
                .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
                .background(PrismediaColor.groupedContentBackground, in: .rect(cornerRadius: PrismediaRadius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.control)
                        .stroke(accent.opacity(0.46), lineWidth: PrismediaLayout.hairline)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Browse \(summary.kind.displayLabel.lowercased()) items")
        }

        private func sectionHeading(title: String, subtitle: String) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
            }
        }

        private func selectionBinding(for entityID: UUID) -> Binding<Bool> {
            Binding(
                get: { session.selectedQueueIDs.contains(entityID) },
                set: { selected in
                    if selected {
                        session.selectedQueueIDs.insert(entityID)
                    } else {
                        session.selectedQueueIDs.remove(entityID)
                    }
                }
            )
        }

        private func stateColor(_ state: IdentifyQueueState) -> Color {
            switch state {
            case .done: PrismediaColor.success
            case .error, .deleted: PrismediaColor.destructive
            case .proposal, .choice: PrismediaColor.materialSpectrumViolet
            case .queued, .searching, .applying: PrismediaColor.materialSpectrumCyan
            case .unknown: PrismediaColor.textSecondary
            }
        }

    }

    #if DEBUG
        #Preview("Identify Dashboard") {
            IdentifyDashboardView(
                session: .init(
                    service: AdministrativePreviewService(),
                    browser: IdentifyPreviewEntityBrowser(),
                    initialQueue: [IdentifyPreviewFixtures.reviewItem, IdentifyPreviewFixtures.errorItem],
                    initialProviders: [IdentifyPreviewFixtures.provider]
                ),
                onOpenKind: { _ in },
                onReviewItem: { _ in },
                onReviewAll: {}
            )
            .frame(width: 940, height: 680)
            .background(PrismediaBackdrop())
        }
    #endif
#endif
