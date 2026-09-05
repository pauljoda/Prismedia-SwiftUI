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
                        Section {
                            NavigationLink {
                                IdentifyQueueView(
                                    session: session,
                                    presentsReviewInNavigationStack: true
                                )
                            } label: {
                                Label {
                                    LabeledContent("Review Queue") {
                                        Text(session.queue.count, format: .number)
                                            .monospacedDigit()
                                    }
                                } icon: {
                                    Image(systemName: "checklist")
                                }
                            }
                            .accessibilityIdentifier("identify.dashboard-queue")
                        } footer: {
                            Text("Review suggested matches before changing your library.")
                        }

                        Section("Find Items to Identify") {
                            ForEach(session.kindSummaries) { summary in
                                NavigationLink(value: summary.kind) {
                                    kindLabel(summary)
                                }
                                .accessibilityIdentifier("identify.kind.\(summary.kind.rawValue)")
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
                Label {
                    Text(summary.kind.displayLabel)
                } icon: {
                    Image(systemName: summary.kind.thumbnailFallbackSystemImage)
                        .foregroundStyle(PrismediaColor.entityAccent(for: summary.kind))
                }
                Spacer()
                if summary.pendingCount > 0 {
                    Text("\(summary.pendingCount) queued")
                        .font(.subheadline)
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
