import SwiftUI

struct AdministrativeJobsView: View {
    @State private var snapshot = AdministrativeJobListResponse(items: [], counts: [])
    @State private var isWorking = true
    @State private var message: String?
    private let service: any AdministrationServicing

    init(service: any AdministrationServicing) { self.service = service }

    var body: some View {
        NavigationStack {
            List {
                if !snapshot.counts.isEmpty {
                    Section("Queues") {
                        ForEach(snapshot.counts) { count in
                            LabeledContent("\(count.type) · \(count.status)", value: count.count.formatted())
                        }
                    }
                }
                Section("Recent Runs") {
                    ForEach(snapshot.items) { job in
                        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                            HStack {
                                Text(job.targetLabel ?? job.type)
                                Spacer()
                                Text(job.status.capitalized).font(.caption).foregroundStyle(.secondary)
                            }
                            ProgressView(value: Double(job.progress), total: 100)
                            if let detail = job.message { Text(detail).font(.caption).foregroundStyle(.secondary) }
                            if job.isCancellable {
                                Button("Cancel", systemImage: "xmark.circle", role: .destructive) {
                                    Task { await cancel(job) }
                                }
                            }
                        }
                    }
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if isWorking && snapshot.items.isEmpty && snapshot.counts.isEmpty {
                    PrismediaLoadingView("Loading jobs…")
                } else if snapshot.items.isEmpty && !isWorking {
                    ContentUnavailableView(
                        "No Job Runs", systemImage: "checkmark.circle",
                        description: Text("Queued and recent background work will appear here."))
                } else if isWorking {
                    ProgressView("Updating jobs…")
                }
            }
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu("Maintenance", systemImage: "ellipsis.circle") {
                        Button("Rebuild previews", systemImage: "photo.badge.arrow.down") {
                            Task { await rebuildPreviews() }
                        }
                        if !failedTypes.isEmpty {
                            Menu("Clear failures") {
                                ForEach(failedTypes, id: \.self) { type in
                                    Button(type) { Task { await clearFailures(type: type) } }
                                }
                            }
                        }
                    }
                    .disabled(isWorking)
                }
            }
            .refreshable { await load() }
            .alert("Jobs", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
        .task { await load() }
        .accessibilityIdentifier("administration.jobs")
    }

    private var failedTypes: [String] {
        Array(Set(snapshot.counts.filter { $0.status == "failed" && $0.count > 0 }.map(\.type))).sorted()
    }

    private func load() async {
        isWorking = true
        defer { isWorking = false }
        do { snapshot = try await service.jobs() } catch { message = error.localizedDescription }
    }

    private func cancel(_ job: AdministrativeJobRun) async {
        isWorking = true
        defer { isWorking = false }
        do {
            message = "Cancelled \(try await service.cancelJob(id: job.id)) job run."
            snapshot = try await service.jobs()
        } catch { message = error.localizedDescription }
    }

    private func clearFailures(type: String) async {
        isWorking = true
        defer { isWorking = false }
        do {
            message = "Cleared \(try await service.clearFailures(type: type)) failed runs."
            snapshot = try await service.jobs()
        } catch { message = error.localizedDescription }
    }

    private func rebuildPreviews() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await service.rebuildPreviews()
            message = "Queued \(result.enqueued) preview jobs; skipped \(result.skipped)."
            snapshot = try await service.jobs()
        } catch { message = error.localizedDescription }
    }
}

#if DEBUG
    #Preview { AdministrativeJobsView(service: AdministrativePreviewService()) }
#endif
