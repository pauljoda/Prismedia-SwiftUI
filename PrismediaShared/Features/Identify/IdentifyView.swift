import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyView: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @State private var session: IdentifySession
        @State private var hasLoaded = false
        @State private var compactNavigationPath = NavigationPath()
        @State private var showsReview = false

        private let automaticallyLoads: Bool

        init(session: IdentifySession, automaticallyLoads: Bool = true) {
            _session = State(initialValue: session)
            self.automaticallyLoads = automaticallyLoads
        }

        var body: some View {
            Group {
                if usesWideWorkspace {
                    wideWorkspace
                } else {
                    compactWorkspace
                }
            }
            .prismediaScreenBackground()
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
            .onReceive(
                NotificationCenter.default.publisher(
                    for: AdministrativeProviderCatalogEvent.didChange
                )
            ) { _ in
                Task { await session.refreshProviders() }
            }
            .onDisappear { session.cancelPolling() }
            .sheet(isPresented: $showsReview) {
                NavigationStack {
                    IdentifyReviewView(session: session)
                }
                .frame(minWidth: reviewSheetMinimumWidth, minHeight: reviewSheetMinimumHeight)
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

        private var compactWorkspace: some View {
            NavigationStack(path: $compactNavigationPath) {
                IdentifySidebarList(
                    session: session,
                    usesNavigationLinks: true,
                    onOpenKind: { compactNavigationPath.append($0) }
                )
                .navigationDestination(for: EntityKind.self) { kind in
                    IdentifyKindBrowseView(session: session, kind: kind)
                }
            }
        }

        private var wideWorkspace: some View {
            VStack(spacing: 0) {
                PrismediaWorkspaceHeaderView(
                    title: "Identify",
                    subtitle:
                        "Match unorganized media with provider metadata and review every proposed change.",
                    systemImage: "sparkles.rectangle.stack.fill",
                    accent: PrismediaColor.materialSpectrumViolet
                )

                IdentifyDestinationBar(session: session, onOpenKind: openKind)

                Divider()

                Group {
                    if let kind = session.selectedKind {
                        IdentifyKindBrowseView(session: session, kind: kind)
                    } else {
                        IdentifyDashboardView(
                            session: session,
                            onOpenKind: openKind,
                            onReviewItem: review,
                            onReviewAll: reviewAll
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(session.selectedKind?.displayLabel ?? "Identify")
        }

        private var usesWideWorkspace: Bool {
            #if os(macOS)
                true
            #else
                horizontalSizeClass == .regular
            #endif
        }

        private var liveRefreshIsActive: Bool {
            pageIsActive && scenePhase == .active
        }

        private var reviewSheetMinimumWidth: CGFloat? {
            #if os(macOS)
                760
            #else
                nil
            #endif
        }

        private var reviewSheetMinimumHeight: CGFloat? {
            #if os(macOS)
                640
            #else
                nil
            #endif
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
    }

    #if DEBUG
        #Preview("Identify · Compact") {
            IdentifyView(
                session: .init(
                    service: AdministrativePreviewService(),
                    browser: IdentifyPreviewEntityBrowser(),
                    initialQueue: [
                        IdentifyPreviewFixtures.reviewItem,
                        IdentifyPreviewFixtures.errorItem,
                    ],
                    initialProviders: [IdentifyPreviewFixtures.provider]
                ),
                automaticallyLoads: false
            )
        }

        #Preview("Identify · Wide") {
            IdentifyView(
                session: .init(
                    service: AdministrativePreviewService(),
                    browser: IdentifyPreviewEntityBrowser(),
                    initialQueue: [
                        IdentifyPreviewFixtures.reviewItem,
                        IdentifyPreviewFixtures.errorItem,
                    ],
                    initialProviders: [IdentifyPreviewFixtures.provider]
                ),
                automaticallyLoads: false
            )
            .frame(width: 1_000, height: 720)
        }
    #endif
#endif
