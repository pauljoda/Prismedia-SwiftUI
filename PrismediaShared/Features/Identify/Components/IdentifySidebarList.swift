import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifySidebarList: View {
        @Bindable var session: IdentifySession
        let usesNavigationLinks: Bool

        var body: some View {
            Group {
                if usesNavigationLinks {
                    List {
                        Section("Work") {
                            NavigationLink {
                                IdentifyQueueView(
                                    session: session,
                                    presentsReviewInNavigationStack: true
                                )
                            } label: {
                                queueLabel
                            }
                        }

                        Section("Library") {
                            ForEach(session.kindSummaries) { summary in
                                NavigationLink {
                                    IdentifyKindBrowseView(session: session, kind: summary.kind)
                                } label: {
                                    kindLabel(summary)
                                }
                            }
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
