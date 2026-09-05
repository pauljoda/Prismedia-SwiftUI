import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyQueueView: View {
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        #if os(iOS)
            @State private var editMode: EditMode = .inactive
        #endif

        @Bindable var session: IdentifySession
        @State private var showsReview = false
        var presentsReviewInNavigationStack = false

        var body: some View {
            List(selection: queueSelection) {
                ForEach(session.queue) { item in
                    queueRow(item)
                        .tag(item.entityID)
                }
            }
            #if os(iOS)
                .environment(\.editMode, $editMode)
            #endif
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
            .navigationDestination(isPresented: $showsReview) {
                IdentifyReviewView(session: session)
            }
            .safeAreaInset(edge: .bottom) {
                IdentifyBulkStatusView(session: session)
                    .padding(.horizontal)
            }
            .toolbar {
                ToolbarItemGroup(placement: trailingToolbarPlacement) {
                    Button {
                        session.reviewAll()
                        if presentsReviewInNavigationStack {
                            showsReview = session.selectedItem != nil
                        }
                    } label: {
                        Image(systemName: "rectangle.stack")
                    }
                    .accessibilityLabel("Review All")
                    .disabled(session.reviewableIDs.isEmpty || isSelecting || session.isMutatingQueue)

                    if queueSelection != nil, !session.selectedQueueIDs.isEmpty {
                        Menu {
                            Button("Accept Selected", systemImage: "checkmark") {
                                Task { await session.acceptSelected() }
                            }
                            .disabled(!session.canAcceptQueueSelection)
                            Button("Reject Selected", systemImage: "trash", role: .destructive) {
                                Task { await session.rejectSelected() }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .accessibilityLabel("Selected Item Actions")
                        .disabled(session.isMutatingQueue)
                    }
                }

                #if os(iOS)
                    ToolbarSpacer(.fixed, placement: trailingToolbarPlacement)
                    ToolbarItem(placement: trailingToolbarPlacement) {
                        selectionToggleButton
                    }
                #endif
            }
            .refreshable {
                await PrismediaRefreshAction.perform {
                    await session.load()
                }
            }
            .task(id: compactRefreshIsActive) {
                guard compactRefreshIsActive else { return }
                while compactRefreshIsActive {
                    do { try await Task.sleep(for: .seconds(10)) } catch { return }
                    guard !Task.isCancelled, compactRefreshIsActive else { return }
                    await session.refreshQueue()
                }
            }
            .accessibilityIdentifier("identify.queue")
        }

        private var compactRefreshIsActive: Bool {
            presentsReviewInNavigationStack && pageIsActive && scenePhase == .active
        }

        private var isSelecting: Bool {
            #if os(iOS)
                editMode.isEditing
            #else
                false
            #endif
        }

        private var queueSelection: Binding<Set<UUID>>? {
            #if os(iOS)
                isSelecting ? $session.selectedQueueIDs : nil
            #else
                $session.selectedQueueIDs
            #endif
        }

        #if os(iOS)
            private var selectionToggleButton: some View {
                Button {
                    withAnimation {
                        if editMode.isEditing {
                            editMode = .inactive
                            session.selectedQueueIDs.removeAll()
                        } else {
                            editMode = .active
                        }
                    }
                } label: {
                    Image(systemName: editMode.isEditing ? "checkmark" : "checkmark.circle")
                }
                .accessibilityLabel(editMode.isEditing ? "Done Selecting" : "Select Items")
                .disabled(session.isMutatingQueue || session.queue.isEmpty)
            }
        #endif

        private var trailingToolbarPlacement: ToolbarItemPlacement {
            #if os(iOS)
                .topBarTrailing
            #else
                .primaryAction
            #endif
        }

        @ViewBuilder
        private func queueRow(_ item: AdministrativeIdentifyQueueItem) -> some View {
            if isSelecting {
                IdentifyQueueRow(item: item)
            } else if presentsReviewInNavigationStack {
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
