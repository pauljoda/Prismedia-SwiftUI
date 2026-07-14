import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifySidebarList: View {
        @Bindable var session: IdentifySession
        let usesNavigationLinks: Bool

        var body: some View {
            List {
                Section("Work") {
                    if usesNavigationLinks {
                        NavigationLink {
                            IdentifyQueueView(
                                session: session,
                                presentsReviewInNavigationStack: true
                            )
                        } label: {
                            queueLabel
                        }
                    } else {
                        Button {
                            session.selectedKind = nil
                            session.selectedItemID = nil
                        } label: {
                            queueLabel
                        }
                        .contentShape(.rect)
                    }
                }

                Section("Library") {
                    ForEach(session.kindSummaries) { summary in
                        if usesNavigationLinks {
                            NavigationLink {
                                IdentifyKindBrowseView(session: session, kind: summary.kind)
                            } label: {
                                kindLabel(summary)
                            }
                        } else {
                            Button {
                                session.selectedKind = summary.kind
                            } label: {
                                kindLabel(summary)
                            }
                            .contentShape(.rect)
                        }
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Identify")
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
