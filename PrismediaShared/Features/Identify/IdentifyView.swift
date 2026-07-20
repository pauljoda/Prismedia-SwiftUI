import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyView: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @State private var session: IdentifySession
        @State private var hasLoaded = false
        private let automaticallyLoads: Bool

        init(session: IdentifySession, automaticallyLoads: Bool = true) {
            _session = State(initialValue: session)
            self.automaticallyLoads = automaticallyLoads
        }

        var body: some View {
            Group {
                if horizontalSizeClass == .compact {
                    NavigationStack {
                        IdentifySidebarList(session: session, usesNavigationLinks: true)
                    }
                } else {
                    NavigationSplitView {
                        IdentifySidebarList(session: session, usesNavigationLinks: false)
                    } content: {
                        if let kind = session.selectedKind {
                            IdentifyKindBrowseView(session: session, kind: kind)
                        } else {
                            IdentifyQueueView(session: session)
                        }
                    } detail: {
                        IdentifyReviewView(session: session)
                    }
                }
            }
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
                await pollQueueWhileVisible()
            }
            .onReceive(NotificationCenter.default.publisher(for: AdministrativeProviderCatalogEvent.didChange)) { _ in
                Task { await session.refreshProviders() }
            }
            .onDisappear { session.cancelPolling() }
            .alert(
                "Identify Unavailable",
                isPresented: Binding(
                    get: { session.errorMessage != nil },
                    set: { if !$0 { session.errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(session.errorMessage ?? "Unknown error")
            }
            .accessibilityIdentifier("identify.root")
        }

        private var liveRefreshIsActive: Bool {
            pageIsActive && scenePhase == .active
        }

        private func pollQueueWhileVisible() async {
            while liveRefreshIsActive {
                do { try await Task.sleep(for: .seconds(10)) } catch { return }
                guard !Task.isCancelled, liveRefreshIsActive else { return }
                await session.refreshQueue()
            }
        }

    }

    #if DEBUG
        #Preview("Identify · Content") {
            IdentifyView(
                session: .init(
                    service: AdministrativePreviewService(), browser: IdentifyPreviewEntityBrowser(),
                    initialQueue: [IdentifyPreviewFixtures.reviewItem, IdentifyPreviewFixtures.errorItem],
                    initialProviders: [IdentifyPreviewFixtures.provider]),
                automaticallyLoads: false)
        }
    #endif
#endif
