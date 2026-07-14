import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyView: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @State private var session: IdentifySession
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
            .task { if automaticallyLoads { await session.load() } }
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
