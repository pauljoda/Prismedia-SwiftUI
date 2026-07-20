import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifySidebarList: View {
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @Bindable var session: IdentifySession
        let usesNavigationLinks: Bool

        var body: some View {
            Group {
                if usesNavigationLinks {
                    List {
                        Section("Browse by Kind") {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: PrismediaSpacing.medium
                            ) {
                                ForEach(session.kindSummaries) { summary in
                                    kindCard(summary)
                                }
                            }
                            .padding(.vertical, PrismediaSpacing.small)
                            .listRowBackground(Color.clear)
                        }

                        if !session.queue.isEmpty {
                            Section {
                                ForEach(session.queue) { item in
                                    NavigationLink {
                                        IdentifyReviewView(session: session)
                                            .task { await session.open(entityID: item.entityID) }
                                    } label: {
                                        IdentifyQueueRow(item: item)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("Review Queue")
                                    Spacer(minLength: 0)
                                    Text("\(session.queue.count) items")
                                }
                            } footer: {
                                NavigationLink {
                                    IdentifyQueueView(
                                        session: session,
                                        presentsReviewInNavigationStack: true
                                    )
                                } label: {
                                    Label("Select and Review All", systemImage: "rectangle.stack")
                                        .font(.callout)
                                }
                                .padding(.top, PrismediaSpacing.small)
                            }
                            .accessibilityIdentifier("identify.dashboard-queue")
                        }
                    }
                } else {
                    List(selection: destinationSelection) {
                        Section("Work") {
                            queueLabel
                                .tag("queue")
                        }

                        Section("Library") {
                            ForEach(session.kindSummaries) { summary in
                                kindLabel(summary)
                                    .tag(summary.kind.rawValue)
                            }
                        }
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Identify")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .task(id: liveRefreshIsActive) {
                guard liveRefreshIsActive else { return }
                while liveRefreshIsActive {
                    do { try await Task.sleep(for: .seconds(10)) } catch { return }
                    guard !Task.isCancelled, liveRefreshIsActive else { return }
                    await session.refreshQueue()
                }
            }
        }

        private var liveRefreshIsActive: Bool {
            pageIsActive && scenePhase == .active
        }

        private var destinationSelection: Binding<String?> {
            Binding(
                get: { session.selectedKind?.rawValue ?? "queue" },
                set: { selection in
                    guard let selection, selection != "queue" else {
                        session.selectedKind = nil
                        session.selectedItemID = nil
                        return
                    }
                    session.selectedKind = EntityKind(rawValue: selection)
                }
            )
        }

        private func kindCard(_ summary: IdentifyKindSummary) -> some View {
            NavigationLink {
                IdentifyKindBrowseView(session: session, kind: summary.kind)
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    Image(systemName: systemImage(for: summary.kind))
                        .font(.title3)
                        .foregroundStyle(
                            summary.pendingCount > 0 ? PrismediaColor.accent : PrismediaColor.textSecondary
                        )

                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(summary.kind.displayLabel)
                            .font(.headline)
                        Text(summary.kind.rawValue)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    if summary.pendingCount > 0 {
                        Text("\(summary.pendingCount) queued")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.accent)
                    }
                }
                .padding(PrismediaSpacing.medium)
                .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: PrismediaRadius.card))
            .accessibilityHint("Browse \(summary.kind.displayLabel.lowercased()) items")
        }

        private var queueLabel: some View {
            HStack {
                Label("Identify Queue", systemImage: "checklist")
                Spacer()
                Text(session.queue.count, format: .number)
                    .foregroundStyle(.secondary)
            }
        }

        private func kindLabel(_ summary: IdentifyKindSummary) -> some View {
            HStack {
                Label(summary.kind.displayLabel, systemImage: "square.grid.2x2")
                Spacer()
                if summary.pendingCount > 0 {
                    Text(summary.pendingCount, format: .number)
                        .foregroundStyle(.secondary)
                }
            }
        }

        private func systemImage(for kind: EntityKind) -> String {
            switch kind {
            case .movie, .video: "film"
            case .videoSeries, .videoSeason: "rectangle.stack"
            case .book, .bookVolume, .bookChapter: "book.closed"
            case .person, .bookAuthor, .musicArtist: "person.crop.circle"
            case .studio: "building.2"
            case .audio, .audioLibrary, .audioTrack: "music.note"
            default: "square.grid.2x2"
            }
        }
    }

    #if DEBUG
        #Preview("Identify Sidebar") {
            NavigationStack {
                IdentifySidebarList(
                    session: .init(
                        service: AdministrativePreviewService(),
                        browser: IdentifyPreviewEntityBrowser(),
                        initialQueue: [IdentifyPreviewFixtures.reviewItem],
                        initialProviders: [IdentifyPreviewFixtures.provider]
                    ),
                    usesNavigationLinks: true
                )
            }
        }
    #endif
#endif
