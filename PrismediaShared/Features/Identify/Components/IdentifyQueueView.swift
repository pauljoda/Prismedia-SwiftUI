import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyQueueView: View {
        @Bindable var session: IdentifySession
        var presentsReviewInNavigationStack = false

        var body: some View {
            List(selection: $session.selectedQueueIDs) {
                ForEach(session.queue) { item in
                    queueRow(item)
                        .tag(item.entityID)
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if session.isLoading && session.queue.isEmpty {
                    PrismediaLoadingView("Loading identify queue…")
                } else if session.isLoading {
                    ProgressView("Updating identify queue…")
                } else if session.queue.isEmpty {
                    ContentUnavailableView(
                        "Queue Is Clear", systemImage: "checkmark.circle",
                        description: Text("Items needing metadata review will appear here."))
                }
            }
            .navigationTitle("Identify Queue")
            .safeAreaInset(edge: .bottom) {
                if let progress = session.bulkProgress, progress.total > 0 {
                    ProgressView(value: progress.fraction) {
                        Text("Processed \(progress.completed) of \(progress.total)")
                    }
                    .padding()
                    .prismediaPanel()
                    .padding(.horizontal)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Review All", systemImage: "rectangle.stack", action: session.reviewAll)
                        .disabled(session.reviewableIDs.isEmpty)
                }
                if !session.selectedQueueIDs.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu("Selected", systemImage: "checkmark.circle") {
                            Button("Accept Selected", systemImage: "checkmark") {
                                Task { await session.acceptSelected() }
                            }
                            .disabled(!session.canAcceptQueueSelection)
                            Button("Reject Selected", systemImage: "trash", role: .destructive) {
                                Task { await session.rejectSelected() }
                            }
                        }
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    #if os(iOS)
                        EditButton()
                    #else
                        EmptyView()
                    #endif
                }
            }
            .refreshable { await session.load() }
            .accessibilityIdentifier("identify.queue")
        }

        @ViewBuilder
        private func queueRow(_ item: AdministrativeIdentifyQueueItem) -> some View {
            if presentsReviewInNavigationStack {
                NavigationLink {
                    IdentifyReviewView(session: session)
                        .task { await session.open(entityID: item.entityID) }
                } label: {
                    IdentifyQueueRow(item: item)
                }
            } else {
                Button {
                    Task { await session.open(entityID: item.entityID) }
                } label: {
                    IdentifyQueueRow(item: item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .contentShape(.rect)
            }
        }
    }

    #if DEBUG
        #Preview("Queue · Content") {
            NavigationStack {
                IdentifyQueueView(
                    session: .init(
                        service: AdministrativePreviewService(), browser: IdentifyPreviewEntityBrowser(),
                        initialQueue: [IdentifyPreviewFixtures.reviewItem, IdentifyPreviewFixtures.errorItem],
                        initialProviders: [IdentifyPreviewFixtures.provider]))
            }
        }

        #Preview("Queue · Empty") {
            NavigationStack {
                IdentifyQueueView(
                    session: .init(service: AdministrativePreviewService(), browser: IdentifyPreviewEntityBrowser()))
            }
        }
    #endif
#endif
