import SwiftUI

struct EntityAcquisitionPanel: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    @State private var state = EntityAcquisitionPanelState()
    @State private var confirmsUnmonitor = false
    private let entityID: UUID
    private let service: EntityAcquisitionService?
    private let onMutated: @MainActor () async -> Void
    private let onEntityPruned: @MainActor () -> Void

    init(
        entityID: UUID,
        acquisitionService: (any EntityAcquisitionServicing)?,
        onMutated: @escaping @MainActor () async -> Void,
        onEntityPruned: @escaping @MainActor () -> Void
    ) {
        self.entityID = entityID
        service = acquisitionService.map(EntityAcquisitionService.init(port:))
        self.onMutated = onMutated
        self.onEntityPruned = onEntityPruned
    }

    var body: some View {
        Group {
            if let service {
                switch state.phase {
                case .loading:
                    ProgressView("Loading acquisition status…")
                        .frame(maxWidth: .infinity, minHeight: 150)
                case .failure(let message):
                    failureView(message, service: service)
                case .content(let snapshot):
                    contentView(snapshot, service: service)
                }
            } else {
                adminUnavailableView
            }
        }
        .task(id: entityID) {
            guard let service else { return }
            await load(using: service)
        }
        .confirmationDialog(
            "Stop monitoring this item?",
            isPresented: $confirmsUnmonitor,
            titleVisibility: .visible
        ) {
            Button("Unmonitor", role: .destructive) {
                guard case .content(let snapshot) = state.phase,
                    let monitor = snapshot.monitor,
                    let service
                else { return }
                Task { await perform(.unmonitor(monitor.id), using: service) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This removes its acquisition and downloads. A fileless wanted placeholder may also be removed from the library."
            )
        }
        .alert("Couldn’t Update Acquisition", isPresented: mutationErrorPresented) {
            Button("OK", role: .cancel) { state.dismissMutationError() }
        } message: {
            Text(state.mutationError ?? "Please try again.")
        }
        .accessibilityIdentifier("entity-detail.acquisition")
    }

    private var adminUnavailableView: some View {
        ContentUnavailableView {
            Label("Administrator Access Required", systemImage: "lock.shield")
        } description: {
            Text("Monitoring and acquisition controls are managed by server administrators.")
        }
        .frame(maxWidth: .infinity)
    }

    private func failureView(
        _ message: String,
        service: EntityAcquisitionService
    ) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Acquisition", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Try Again", variant: .prominent) {
                Task { await load(using: service) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func contentView(
        _ snapshot: EntityMonitorState,
        service: EntityAcquisitionService
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
            capabilityContent(snapshot)

            if let monitor = snapshot.monitor {
                monitorContent(monitor)
            }

            if let acquisition = snapshot.latestAcquisition {
                acquisitionContent(acquisition)
            }

            actionContent(snapshot, service: service)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func capabilityContent(_ snapshot: EntityMonitorState) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Label(
                snapshot.canMonitor ? "Eligible for monitoring" : "Monitoring unavailable",
                systemImage: snapshot.canMonitor ? "checkmark.shield" : "exclamationmark.shield"
            )
            .font(.headline)
            .foregroundStyle(snapshot.canMonitor ? artworkPrimaryAccent : artworkSecondaryText)

            if snapshot.trackableProviders.isEmpty {
                Text(
                    "No enabled metadata provider can track this entity yet. Identify it with a supported provider first."
                )
                .font(.subheadline)
                .foregroundStyle(artworkSecondaryText)
            } else {
                LabeledContent("Providers", value: snapshot.trackableProviders.joined(separator: ", "))
            }

            if snapshot.discoversChildren {
                Label("Discovers new child items from its provider", systemImage: "arrow.triangle.branch")
                    .font(.subheadline)
                    .foregroundStyle(artworkSecondaryText)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func monitorContent(_ monitor: EntityMonitor) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text("Monitor")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LabeledContent("Status", value: monitor.status.displayName)
            LabeledContent("Preset", value: monitor.preset.displayName)
            LabeledContent("Updated", value: monitor.updatedAt.formatted(date: .abbreviated, time: .shortened))
        }
    }

    private func acquisitionContent(_ acquisition: EntityAcquisitionSummary) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text("Latest Acquisition")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LabeledContent("Status", value: acquisition.status.displayName)

            if let progress = acquisition.progress {
                ProgressView(value: min(max(progress, 0), 1)) {
                    Text("Download progress")
                } currentValueLabel: {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                .accessibilityValue(
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                )
            }

            if let message = acquisition.statusMessage, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(artworkSecondaryText)
            }
        }
    }

    private func actionContent(
        _ snapshot: EntityMonitorState,
        service: EntityAcquisitionService
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PrismediaSpacing.medium) {
                actionButtons(snapshot, service: service)
            }
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                actionButtons(snapshot, service: service)
            }
        }
        .disabled(state.isMutating)
        .overlay {
            if state.isMutating {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private func actionButtons(
        _ snapshot: EntityMonitorState,
        service: EntityAcquisitionService
    ) -> some View {
        if snapshot.monitor == nil, snapshot.canMonitor {
            PrismediaButton(
                "Start Monitor",
                systemImage: "eye",
                variant: .prominent
            ) {
                Task { await perform(.start(entityID), using: service) }
            }
        }

        if let monitor = snapshot.monitor {
            if monitor.status == .active {
                PrismediaButton("Pause", systemImage: "pause") {
                    Task { await perform(.pause(monitor.id), using: service) }
                }
            } else if monitor.status == .paused {
                PrismediaButton(
                    "Resume",
                    systemImage: "play",
                    variant: .prominent
                ) {
                    Task { await perform(.resume(monitor.id), using: service) }
                }
            }

            PrismediaButton(
                "Unmonitor",
                systemImage: "trash",
                variant: .destructive
            ) {
                confirmsUnmonitor = true
            }
            .disabled(monitor.status == .deletingFiles || monitor.status == .stopping)
        }

        if let acquisition = snapshot.latestAcquisition {
            PrismediaButton("Search Again", systemImage: "arrow.clockwise") {
                Task { await perform(.searchAgain(acquisition.id), using: service) }
            }
        }
    }

    private func load(using service: EntityAcquisitionService) async {
        let outcome = await service.load(entityID: entityID)
        state.finishLoad(outcome)
    }

    private func perform(
        _ command: EntityAcquisitionCommand,
        using service: EntityAcquisitionService
    ) async {
        guard state.beginMutation() else { return }
        let outcome = await service.perform(command)
        switch state.finishMutation(outcome) {
        case .entityPruned:
            onEntityPruned()
        case .refresh:
            await load(using: service)
            await onMutated()
        case .none:
            break
        }
    }

    private var mutationErrorPresented: Binding<Bool> {
        Binding(
            get: { state.mutationError != nil },
            set: { isPresented in
                if !isPresented { state.dismissMutationError() }
            }
        )
    }
}

extension EntityMonitorStatus {
    fileprivate var displayName: String {
        rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

extension AcquisitionStatus {
    fileprivate var displayName: String {
        rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

extension String {
    fileprivate var displayName: String {
        replacingOccurrences(of: "-", with: " ").capitalized
    }
}

#if DEBUG
    #Preview("Entity Acquisition · Downloading") {
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let monitorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let acquisitionID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let updatedAt = Date(timeIntervalSince1970: 1_783_792_800)
        let snapshot = EntityMonitorState(
            entityID: entityID,
            canMonitor: true,
            canRequest: true,
            trackableProviders: ["Open Library"],
            discoversChildren: false,
            canSearchMissingChildren: false,
            missingChildEntityKind: nil,
            monitor: EntityMonitor(
                id: monitorID,
                kind: .book,
                acquisitionID: acquisitionID,
                status: .active,
                title: "The Work",
                author: "Author",
                acquisitionStatus: AcquisitionStatus(rawValue: "downloading"),
                createdAt: updatedAt,
                updatedAt: updatedAt,
                entityID: entityID,
                preset: "all"
            ),
            latestAcquisition: EntityAcquisitionSummary(
                id: acquisitionID,
                status: AcquisitionStatus(rawValue: "downloading"),
                statusMessage: "Fetching release",
                title: "The Work",
                author: "Author",
                progress: 0.42,
                createdAt: updatedAt,
                updatedAt: updatedAt,
                entityID: entityID
            )
        )

        EntityAcquisitionPanel(
            entityID: entityID,
            acquisitionService: PreviewEntityAcquisitionService(snapshot: snapshot),
            onMutated: {},
            onEntityPruned: {}
        )
        .padding()
        .frame(width: 560)
    }
#endif
