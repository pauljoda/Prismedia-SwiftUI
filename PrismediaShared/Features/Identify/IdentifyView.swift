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
                        compactContent
                            .safeAreaInset(edge: .top, spacing: 0) {
                                compactScopePicker
                            }
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

        @ViewBuilder
        private var compactContent: some View {
            if let kind = session.selectedKind {
                IdentifyKindBrowseView(session: session, kind: kind)
            } else {
                IdentifySidebarList(session: session, usesNavigationLinks: true)
            }
        }

        private var compactScopePicker: some View {
            ScrollView(.horizontal) {
                Picker("Identify Scope", selection: scopeSelection) {
                    Label("Dashboard", systemImage: "house").tag("dashboard")
                    ForEach(session.kindSummaries) { summary in
                        Text(summary.kind.displayLabel).tag(summary.kind.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("identify.scope")
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal)
            .padding(.vertical, PrismediaSpacing.medium)
            .background(.bar)
        }

        private var scopeSelection: Binding<String> {
            Binding(
                get: { session.selectedKind?.rawValue ?? "dashboard" },
                set: { selection in
                    session.selectedBrowseIDs.removeAll()
                    session.selectedKind = selection == "dashboard" ? nil : EntityKind(rawValue: selection)
                }
            )
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
