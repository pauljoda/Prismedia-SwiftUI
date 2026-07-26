#if os(macOS)
    import SwiftUI

    struct MacIdentifyView: View {
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @State private var session: IdentifySession
        @State private var hasLoaded = false
        @State private var showsReview = false

        private let automaticallyLoads: Bool

        init(session: IdentifySession, automaticallyLoads: Bool = true) {
            _session = State(initialValue: session)
            self.automaticallyLoads = automaticallyLoads
        }

        var body: some View {
            VStack(spacing: 0) {
                MacWorkspaceHeaderView(
                    title: "Identify",
                    subtitle: "Match unorganized media with provider metadata and review every proposed change.",
                    systemImage: "sparkles.rectangle.stack.fill",
                    accent: PrismediaColor.materialSpectrumViolet
                )

                destinationBar

                Divider()

                Group {
                    if let kind = session.selectedKind {
                        IdentifyKindBrowseView(session: session, kind: kind)
                    } else {
                        MacIdentifyDashboardView(
                            session: session,
                            onOpenKind: openKind,
                            onReviewItem: review,
                            onReviewAll: reviewAll
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .prismediaScreenBackground()
            .navigationTitle(session.selectedKind?.displayLabel ?? "Identify")
            .task(id: liveRefreshIsActive) {
                guard automaticallyLoads, liveRefreshIsActive else {
                    session.cancelPolling()
                    return
                }
                if hasLoaded {
                    await session.refreshQueue()
                } else {
                    await session.load()
                    guard !Task.isCancelled else { return }
                    hasLoaded = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: AdministrativeProviderCatalogEvent.didChange)) { _ in
                Task { await session.refreshProviders() }
            }
            .onDisappear { session.cancelPolling() }
            .sheet(isPresented: $showsReview) {
                NavigationStack {
                    IdentifyReviewView(session: session)
                }
                .frame(minWidth: 760, minHeight: 640)
            }
            .alert(
                "Identify Unavailable",
                isPresented: Binding(
                    get: { session.errorMessage != nil },
                    set: { if !$0 { session.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(session.errorMessage ?? "Unknown error")
            }
            .accessibilityIdentifier("identify.root")
        }

        private var destinationBar: some View {
            ScrollView(.horizontal) {
                HStack(spacing: PrismediaSpacing.extraLarge) {
                    destinationButton(
                        title: "Dashboard",
                        systemImage: "rectangle.grid.2x2",
                        pendingCount: session.queue.count,
                        isSelected: session.selectedKind == nil
                    ) {
                        session.selectedKind = nil
                    }

                    ForEach(session.kindSummaries) { summary in
                        destinationButton(
                            title: summary.kind.displayLabel,
                            systemImage: systemImage(for: summary.kind),
                            pendingCount: summary.pendingCount,
                            isSelected: session.selectedKind == summary.kind
                        ) {
                            openKind(summary.kind)
                        }
                    }
                }
                .padding(.horizontal, PrismediaSpacing.extraExtraLarge)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("identify.destination-bar")
        }

        private func destinationButton(
            title: String,
            systemImage: String,
            pendingCount: Int,
            isSelected: Bool,
            action: @escaping () -> Void
        ) -> some View {
            Button(action: action) {
                VStack(spacing: PrismediaSpacing.small) {
                    HStack(spacing: PrismediaSpacing.extraSmall) {
                        Label(title, systemImage: systemImage)
                        if pendingCount > 0 {
                            Text(pendingCount, format: .number)
                                .font(.caption2.monospacedDigit().weight(.semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(PrismediaColor.controlFill, in: .capsule)
                        }
                    }
                    .font(.callout.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? PrismediaColor.textPrimary : PrismediaColor.textSecondary)

                    Rectangle()
                        .fill(isSelected ? PrismediaColor.materialSpectrumViolet : .clear)
                        .frame(height: 2)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var liveRefreshIsActive: Bool {
            pageIsActive && scenePhase == .active
        }

        private func openKind(_ kind: EntityKind) {
            session.prepareBrowse(kind: kind)
        }

        private func review(_ item: AdministrativeIdentifyQueueItem) {
            Task {
                await session.open(entityID: item.entityID)
                showsReview = true
            }
        }

        private func reviewAll() {
            session.reviewAll()
            showsReview = session.selectedItem != nil
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
        #Preview("Mac Identify") {
            PreviewShell(signedIn: true) {
                MacIdentifyView(
                    session: .init(
                        service: AdministrativePreviewService(),
                        browser: IdentifyPreviewEntityBrowser(),
                        initialQueue: [IdentifyPreviewFixtures.reviewItem, IdentifyPreviewFixtures.errorItem],
                        initialProviders: [IdentifyPreviewFixtures.provider]
                    ),
                    automaticallyLoads: false
                )
            }
            .frame(width: 1_000, height: 720)
        }
    #endif
#endif
