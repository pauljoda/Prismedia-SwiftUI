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
                statusSection
                scanSection
                maintenanceSection
                activitySections
            }
            .prismediaScreenBackground()
            .overlay {
                if isWorking && snapshot.items.isEmpty && snapshot.counts.isEmpty {
                    PrismediaLoadingView("Loading jobs…")
                }
            }
            .navigationTitle("Job Control")
            .refreshable { await load() }
            .alert("Jobs", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
        .task {
            await load()
            await pollWhileVisible()
        }
        .accessibilityIdentifier("administration.jobs")
    }

    private var statusSection: some View {
        Section {
            HStack(spacing: PrismediaSpacing.large) {
                statusLabel("Active", count: activeCount, systemImage: "arrow.triangle.2.circlepath")
                statusLabel("Queued", count: queuedCount, systemImage: "clock")
                statusLabel("Failed", count: failedCount, systemImage: "exclamationmark.triangle")
            }

            HStack(spacing: PrismediaSpacing.medium) {
                if failedCount > 0 {
                    Button("Clear Failures", systemImage: "xmark.circle") {
                        Task { await clearFailures(type: nil) }
                    }
                }

                if activeCount + queuedCount > 0 {
                    Button("Kill All", systemImage: "stop.fill", role: .destructive) {
                        Task { await cancelJobs(type: nil) }
                    }
                }

                Spacer(minLength: 0)

                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await load() }
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel("Refresh Jobs")
            }
            .disabled(isWorking)
        } header: {
            Label("Worker Activity", systemImage: "waveform.path.ecg")
        }
    }

    private var scanSection: some View {
        Section("Scans") {
            catalogRow(
                type: "scan-library",
                title: "Videos",
                description: "Walk library roots for new video files.",
                systemImage: "folder.badge.magnifyingglass"
            )
            catalogRow(
                type: "scan-gallery",
                title: "Images",
                description: "Walk library roots for image galleries.",
                systemImage: "photo.on.rectangle"
            )
            catalogRow(
                type: "scan-book",
                title: "Books",
                description: "Walk library roots for comic archives.",
                systemImage: "book.closed"
            )
            catalogRow(
                type: "scan-audio",
                title: "Audio",
                description: "Walk library roots for audio tracks.",
                systemImage: "music.note"
            )
        }
    }

    private var maintenanceSection: some View {
        Section("Maintenance") {
            catalogRow(
                type: "refresh-collection",
                title: "Refresh Collections",
                description: "Re-evaluate dynamic collection rules.",
                systemImage: "arrow.clockwise"
            )
            catalogRow(
                type: "monitored-search",
                title: "Check Monitored Items",
                description: "Re-search wanted items and sync followed authors/artists now.",
                systemImage: "magnifyingglass"
            )
        }
    }

    @ViewBuilder
    private var activitySections: some View {
        if activeCount > 0 {
            Section {
                if runningJobs.isEmpty {
                    Text("\(activeCount) active job\(activeCount == 1 ? "" : "s") not included in recent runs.")
                        .foregroundStyle(PrismediaColor.textSecondary)
                } else {
                    jobGroups(runningJobs, statusLabel: "running")
                }
            } header: {
                Label("Running Now · \(activeCount)", systemImage: "arrow.triangle.2.circlepath")
            }
        }

        if queuedCount > 0 {
            Section {
                if queuedJobs.isEmpty {
                    Text("\(queuedCount) queued job\(queuedCount == 1 ? "" : "s") waiting.")
                        .foregroundStyle(PrismediaColor.textSecondary)
                } else {
                    jobGroups(queuedJobs, statusLabel: "queued")
                }
            } header: {
                Label("Queued · \(queuedCount)", systemImage: "clock")
            }
        }

        if failedCount > 0 {
            Section {
                if failedJobs.isEmpty {
                    Text("\(failedCount) failed job\(failedCount == 1 ? "" : "s") not included in recent runs.")
                        .foregroundStyle(PrismediaColor.textSecondary)
                } else {
                    jobGroups(failedJobs, statusLabel: "failed")
                }
            } header: {
                Label("Needs Attention · \(failedCount)", systemImage: "exclamationmark.triangle")
            }
        }

        if !completedJobs.isEmpty {
            Section("Recently Completed") {
                jobGroups(completedJobs, statusLabel: "completed", initiallyExpanded: false)
            }
        }

        if snapshot.items.isEmpty && activeCount + queuedCount + failedCount == 0 && !isWorking {
            Section("Activity") {
                ContentUnavailableView(
                    "All Quiet",
                    systemImage: "checkmark.circle",
                    description: Text("Run a job from the controls above to get started.")
                )
            }
        }
    }

    private func statusLabel(_ title: String, count: Int, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(PrismediaColor.textSecondary)
            Text(count, format: .number)
                .font(.title3.monospacedDigit().weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func catalogRow(
        type: String,
        title: String,
        description: String,
        systemImage: String
    ) -> some View {
        AdministrativeJobCatalogRow(
            title: title,
            description: description,
            systemImage: systemImage,
            activeCount: count(type: type, statuses: activeStatuses),
            queuedCount: count(type: type, statuses: queuedStatuses),
            failedCount: count(type: type, statuses: failedStatuses),
            isWorking: isWorking,
            onRun: { Task { await createJob(type: type) } },
            onStop: { Task { await cancelJobs(type: type) } },
            onClearFailures: { Task { await clearFailures(type: type) } }
        )
    }

    @ViewBuilder
    private func jobGroups(
        _ jobs: [AdministrativeJobRun],
        statusLabel: String,
        initiallyExpanded: Bool = true
    ) -> some View {
        ForEach(grouped(jobs), id: \.type) { group in
            AdministrativeJobGroupView(
                title: displayName(for: group.type),
                jobs: group.jobs,
                statusLabel: statusLabel,
                isWorking: isWorking,
                initiallyExpanded: initiallyExpanded,
                onCancel: { job in Task { await cancel(job) } }
            )
        }
    }

    private var activeStatuses: Set<String> { ["active", "running"] }
    private var queuedStatuses: Set<String> { ["waiting", "queued", "delayed"] }
    private var failedStatuses: Set<String> { ["failed"] }

    private var activeCount: Int { totalCount(statuses: activeStatuses) }
    private var queuedCount: Int { totalCount(statuses: queuedStatuses) }
    private var failedCount: Int { totalCount(statuses: failedStatuses) }

    private var runningJobs: [AdministrativeJobRun] { jobs(statuses: activeStatuses) }
    private var queuedJobs: [AdministrativeJobRun] { jobs(statuses: queuedStatuses) }
    private var failedJobs: [AdministrativeJobRun] { jobs(statuses: failedStatuses) }
    private var completedJobs: [AdministrativeJobRun] { jobs(statuses: ["completed"]) }

    private func totalCount(statuses: Set<String>) -> Int {
        snapshot.counts
            .filter { statuses.contains($0.status.lowercased()) }
            .reduce(0) { $0 + $1.count }
    }

    private func count(type: String, statuses: Set<String>) -> Int {
        snapshot.counts
            .filter { $0.type == type && statuses.contains($0.status.lowercased()) }
            .reduce(0) { $0 + $1.count }
    }

    private func jobs(statuses: Set<String>) -> [AdministrativeJobRun] {
        snapshot.items.filter { statuses.contains($0.status.lowercased()) }
    }

    private func grouped(
        _ jobs: [AdministrativeJobRun]
    ) -> [(type: String, jobs: [AdministrativeJobRun])] {
        Dictionary(grouping: jobs, by: \.type)
            .map { (type: $0.key, jobs: $0.value) }
            .sorted { displayName(for: $0.type).localizedStandardCompare(displayName(for: $1.type)) == .orderedAscending }
    }

    private func displayName(for type: String) -> String {
        type.replacingOccurrences(of: "-", with: " ").capitalized
    }

    private func load(showsProgress: Bool = true) async {
        if showsProgress { isWorking = true }
        defer { if showsProgress { isWorking = false } }
        do { snapshot = try await service.jobs() } catch { message = error.localizedDescription }
    }

    private func pollWhileVisible() async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                return
            }
            await load(showsProgress: false)
        }
    }

    private func createJob(type: String) async {
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await service.createJob(type: type)
            message = "Queued \(displayName(for: type))."
            snapshot = try await service.jobs()
        } catch { message = error.localizedDescription }
    }

    private func cancel(_ job: AdministrativeJobRun) async {
        isWorking = true
        defer { isWorking = false }
        do {
            message = "Cancelled \(try await service.cancelJob(id: job.id)) job run."
            snapshot = try await service.jobs()
        } catch { message = error.localizedDescription }
    }

    private func cancelJobs(type: String?) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let cancelled = try await service.cancelJobs(type: type)
            message = "Cancelled \(cancelled) job\(cancelled == 1 ? "" : "s")."
            snapshot = try await service.jobs()
        } catch { message = error.localizedDescription }
    }

    private func clearFailures(type: String?) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let cleared = try await service.clearFailures(type: type)
            message = "Cleared \(cleared) failed job\(cleared == 1 ? "" : "s")."
            snapshot = try await service.jobs()
        } catch { message = error.localizedDescription }
    }
}

#if DEBUG
    #Preview { AdministrativeJobsView(service: AdministrativePreviewService()) }
#endif
