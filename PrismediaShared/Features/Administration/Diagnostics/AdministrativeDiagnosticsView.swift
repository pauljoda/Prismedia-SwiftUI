import SwiftUI

struct AdministrativeDiagnosticsView: View {
    @State private var snapshot: AdministrativeDiagnosticsSnapshot?
    @State private var isLoading = true
    @State private var action: String?
    @State private var confirmation: String?
    @State private var message: String?
    let isAdministrator: Bool
    let service: any DiagnosticsServicing

    var body: some View {
        Form {
            if let snapshot {
                Section("Runtime Health") {
                    LabeledContent("API", value: snapshot.health.status.capitalized)
                    LabeledContent("Runtime", value: snapshot.health.runtime ?? "Unknown")
                    LabeledContent("Worker", value: snapshot.worker.status.capitalized)
                    LabeledContent("Worker ID", value: snapshot.worker.workerID ?? "Not reported")
                    LabeledContent("Last heartbeat") {
                        Text(snapshot.worker.lastSeenAt?.formatted(.dateTime) ?? "Never")
                    }
                    LabeledContent("Database restore", value: restoreLabel(snapshot.restore))
                }
                Section("Storage") {
                    LabeledContent("Backup directory") {
                        Text(snapshot.backups.backupDirectory).font(.body.monospaced()).prismediaTextSelection()
                    }
                    LabeledContent("Retention", value: "\(snapshot.backups.automaticRetentionDays) days")
                    LabeledContent("Backup records", value: snapshot.backups.backups.count.formatted())
                }
                Section("Diagnostic Summary") {
                    Text(summary(snapshot)).font(.caption.monospaced()).prismediaTextSelection()
                    #if !os(tvOS)
                        ShareLink(item: summary(snapshot)) {
                            Label("Export Summary", systemImage: "square.and.arrow.up")
                        }
                    #endif
                }
            }
            if let message {
                Section {
                    Text(message).foregroundStyle(message.hasPrefix("Queued") ? .secondary : PrismediaColor.destructive)
                }
            }
            if isAdministrator {
                Section {
                    Button("Backfill Missing Fingerprints", systemImage: "number") { Task { await backfill() } }
                        .disabled(action != nil)
                    Button("Force Rebuild All Previews", systemImage: "photo.badge.arrow.down", role: .destructive) {
                        confirmation = "previews"
                    }
                    .disabled(action != nil)
                } header: {
                    Text("Maintenance")
                } footer: {
                    Text(
                        "These actions enqueue background work. Preview regeneration is a heavy operation and does not delete source media."
                    )
                }
            }
        }
        .overlay { if isLoading && snapshot == nil { PrismediaLoadingView("Loading diagnostics…") } }
        .prismediaScreenBackground()
        .navigationTitle("Diagnostics")
        .toolbar { Button("Refresh", systemImage: "arrow.clockwise") { Task { await load() } }.disabled(isLoading) }
        .task { await load() }
        .refreshable { await load() }
        .confirmationDialog(
            "Rebuild every generated preview?",
            isPresented: Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } }),
            titleVisibility: .visible
        ) {
            Button("Queue Rebuild", role: .destructive) { Task { await rebuild() } }
        } message: {
            Text("Every video, image, book page, and audio track will be queued for preview regeneration.")
        }
        .accessibilityIdentifier("administration.settings.diagnostics")
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            snapshot = try await service.snapshot()
            message = nil
        } catch { message = error.localizedDescription }
    }

    private func backfill() async {
        action = "fingerprints"
        defer { action = nil }
        do {
            let result = try await service.backfillFingerprints()
            message = "Queued \(result.enqueued) entities for fingerprint generation (\(result.skipped) skipped)."
        } catch { message = error.localizedDescription }
    }

    private func rebuild() async {
        confirmation = nil
        action = "previews"
        defer { action = nil }
        do {
            let result = try await service.rebuildPreviews()
            message = "Queued \(result.enqueued) entities for preview regeneration (\(result.skipped) skipped)."
        } catch { message = error.localizedDescription }
    }

    private func restoreLabel(_ status: AdministrativeDatabaseRestoreStatus) -> String {
        if status.restoreFailed { return "Failed" }
        if status.restorePending { return "Pending" }
        return "Ready"
    }

    private func summary(_ value: AdministrativeDiagnosticsSnapshot) -> String {
        "Prismedia diagnostics\nAPI: \(value.health.status) (\(value.health.runtime ?? "unknown"))\nWorker: \(value.worker.status)\nBackup records: \(value.backups.backups.count)\nRestore: \(restoreLabel(value.restore))"
    }
}

#if DEBUG
    #Preview("Diagnostics · Regular Width") {
        NavigationStack {
            AdministrativeDiagnosticsView(isAdministrator: true, service: Step3AdministrationPreviewService())
        }
        .frame(width: 760, height: 700)
    }
#endif
