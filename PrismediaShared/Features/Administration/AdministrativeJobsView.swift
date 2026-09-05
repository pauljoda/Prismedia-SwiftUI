import SwiftUI

struct AdministrativeJobsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: AdministrativeJobSession
    @State private var pendingCommand: AdministrativeJobCommand?

    init(service: any AdministrationServicing) {
        _session = State(initialValue: AdministrativeJobSession(service: service))
    }

    var body: some View {
        NavigationStack {
            List {
                AdministrativeJobFeedbackView(session: session)
                if session.hasLoaded {
                    AdministrativeJobStatusSection(snapshot: session.snapshot)
                    AdministrativeJobActivitySections(
                        snapshot: session.snapshot, isWorking: session.isMutating,
                        onCancel: { pendingCommand = .cancel(id: $0.id) })
                    AdministrativeJobCatalogSections(
                        snapshot: session.snapshot, isWorking: session.isMutating,
                        onRun: { command in Task { await session.perform(command) } },
                        onConfirm: { pendingCommand = $0 })
                    AdministrativeJobHistorySection(snapshot: session.snapshot)
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if !session.hasLoaded && session.isRefreshing && session.refreshError == nil {
                    PrismediaLoadingView("Loading jobs…")
                }
            }
            .navigationTitle("Job Control")
            .refreshable {
                await PrismediaRefreshAction.perform { await session.refresh() }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Job Actions", systemImage: "ellipsis") {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task { await session.refresh() }
                        }
                        .disabled(session.isRefreshing)
                        if session.snapshot.failedCount > 0 {
                            Button("Clear All Failures", systemImage: "xmark.circle", role: .destructive) {
                                pendingCommand = .clearFailures(type: nil)
                            }
                        }
                        if session.snapshot.activeCount + session.snapshot.queuedCount > 0 {
                            Button("Stop All Jobs", systemImage: "stop.fill", role: .destructive) {
                                pendingCommand = .stop(type: nil)
                            }
                        }
                    }
                    .disabled(session.isMutating)
                }
            }
            .confirmationDialog(
                pendingCommand?.confirmationTitle ?? "Confirm Action",
                isPresented: Binding(get: { pendingCommand != nil }, set: { if !$0 { pendingCommand = nil } }),
                titleVisibility: .visible, presenting: pendingCommand
            ) { command in
                Button(command.actionTitle, role: .destructive) {
                    Task { await session.perform(command) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { command in
                Text(command.confirmationMessage)
            }
            .alert(
                "Couldn't Complete Action",
                isPresented: Binding(
                    get: { session.actionError != nil }, set: { if !$0 { session.actionError = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(session.actionError ?? "")
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await session.refresh()
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                await session.refresh()
            }
        }
        .accessibilityIdentifier("administration.jobs")
    }
}

#if DEBUG
    #Preview { AdministrativeJobsView(service: AdministrativePreviewService()) }
#endif
