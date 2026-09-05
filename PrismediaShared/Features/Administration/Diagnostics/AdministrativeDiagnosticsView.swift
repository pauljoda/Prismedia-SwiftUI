import SwiftUI

struct AdministrativeDiagnosticsView: View {
    @State private var snapshot = AdministrativeCollectionLoadState<AdministrativeDiagnosticsSnapshot>()
    @State private var action: AdministrativeMaintenanceAction?
    @State private var confirmation: AdministrativeMaintenanceAction?
    @State private var completionMessage: String?
    @State private var actionError: String?
    let isAdministrator: Bool
    let service: any DiagnosticsServicing

    var body: some View {
        Form {
            if let error = snapshot.errorMessage {
                PrismediaRetryView(
                    title: "Couldn't Load Diagnostics", message: error,
                    retry: { Task { await load() } })
            }
            if let action {
                Section { ProgressView(action.progressTitle) }
            } else if let completionMessage {
                Section { Text(completionMessage) }
            }
            if let value = snapshot.items.first {
                AdministrativeDiagnosticsStatusSections(snapshot: value)
                Section("Support") {
                    #if !os(tvOS)
                        ShareLink(item: summary(value)) {
                            Label("Export Summary", systemImage: "square.and.arrow.up")
                        }
                    #else
                        Text(summary(value)).font(.caption.monospaced())
                    #endif
                }
            }
            if isAdministrator {
                Section {
                    ForEach(AdministrativeMaintenanceAction.allCases, id: \.self) { candidate in
                        Button(role: candidate == .previews ? .destructive : nil) {
                            confirmation = candidate
                        } label: {
                            FullWidthButtonLabel {
                                Label(candidate.title, systemImage: candidate.systemImage)
                            }
                        }
                        .disabled(action != nil || !snapshot.isReady)
                    }
                } header: {
                    Text("Maintenance")
                } footer: {
                    Text("These actions queue background work. Review the confirmation before proceeding.")
                }
            }
        }
        .prismediaSettingsForm()
        .overlay {
            if snapshot.isLoading && snapshot.items.isEmpty {
                PrismediaLoadingView("Loading diagnostics…")
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Diagnostics")
        .toolbar {
            PrismediaToolbarActionButton("Refresh Diagnostics", systemImage: "arrow.clockwise") {
                Task { await load() }
            }
            .disabled(snapshot.isLoading || action != nil)
        }
        .task { await load() }
        .refreshable { await PrismediaRefreshAction.perform { await load() } }
        .confirmationDialog(
            confirmation?.confirmationTitle ?? "Queue maintenance?",
            isPresented: Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } }),
            titleVisibility: .visible
        ) {
            if let confirmation {
                Button("Queue Work", role: confirmation == .previews ? .destructive : nil) {
                    Task { await perform(confirmation) }
                }
            }
        } message: {
            Text(confirmation?.explanation ?? "")
        }
        .alert(
            "Couldn't Queue Maintenance",
            isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
        }
        .accessibilityIdentifier("administration.settings.diagnostics")
    }

    private func load() async {
        guard action == nil else { return }
        let request = snapshot.begin()
        do {
            let loaded = try await service.snapshot()
            snapshot.succeed([loaded], request: request, isCancelled: Task.isCancelled)
        } catch {
            snapshot.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    private func perform(_ selected: AdministrativeMaintenanceAction) async {
        guard isAdministrator, action == nil, snapshot.isReady else { return }
        confirmation = nil
        action = selected
        completionMessage = nil
        actionError = nil
        defer { action = nil }
        do {
            let result: AdministrativeBulkJobResponse
            switch selected {
            case .fingerprints: result = try await service.backfillFingerprints()
            case .previews: result = try await service.rebuildPreviews()
            }
            completionMessage = "\(selected.title): \(result.enqueued) queued, \(result.skipped) skipped."
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func summary(_ value: AdministrativeDiagnosticsSnapshot) -> String {
        let restore = value.restore.restoreFailed ? "Failed" : (value.restore.restorePending ? "Pending" : "Ready")
        return "Prismedia diagnostics\nAPI: \(value.health.status) (\(value.health.runtime ?? "unknown"))\nWorker: \(value.worker.status)\nBackup records: \(value.backups.backups.count)\nRestore: \(restore)"
    }
}

#if DEBUG
    #Preview("Diagnostics · Regular Width") {
        NavigationStack {
            AdministrativeDiagnosticsView(isAdministrator: true, service: Step3AdministrationPreviewService())
        }
        .frame(width: 760, height: 700)
    }
    #Preview("Diagnostics · Accessibility") {
        NavigationStack {
            AdministrativeDiagnosticsView(isAdministrator: true, service: Step3AdministrationPreviewService())
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
