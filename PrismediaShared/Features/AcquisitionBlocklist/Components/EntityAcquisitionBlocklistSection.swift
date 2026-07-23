import SwiftUI

struct EntityAcquisitionBlocklistSection: View {
    @State private var entryCount: Int?
    @State private var confirmsClear = false
    @State private var isClearing = false
    @State private var message: String?
    private let entityID: UUID
    private let service: EntityAcquisitionService

    init(entityID: UUID, service: EntityAcquisitionService) {
        self.entityID = entityID
        self.service = service
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            HStack {
                Label("Blocklist", systemImage: "nosign")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let entryCount {
                    Text(entryCount, format: .number)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Text(blocklistDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                confirmsClear = true
            } label: {
                HStack {
                    Label("Clear Blocklist for This Item", systemImage: "arrow.uturn.backward")
                    Spacer()
                    if isClearing { ProgressView() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .disabled(isClearing || entryCount == 0)

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: entityID) { await loadCount() }
        .confirmationDialog(
            "Allow all blocked releases for this item again?",
            isPresented: $confirmsClear,
            titleVisibility: .visible
        ) {
            Button("Clear Blocklist", role: .destructive) {
                Task { await clear() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("These releases can be selected for download again.")
        }
    }

    private func loadCount() async {
        do {
            entryCount = try await service.acquisitionBlocklist(entityID: entityID).count
        } catch {
            entryCount = nil
            message = "The current count couldn’t be loaded. You can still clear this item’s blocklist."
        }
    }

    private func clear() async {
        isClearing = true
        defer { isClearing = false }
        do {
            let removed = try await service.clearAcquisitionBlocklist(entityID: entityID)
            entryCount = 0
            message = removed == 1 ? "Cleared 1 blocked release." : "Cleared \(removed) blocked releases."
        } catch {
            message = error.localizedDescription
        }
    }

    private var blocklistDescription: String {
        guard let entryCount else {
            return "Clear failed or stale release blocks associated with this item."
        }
        if entryCount == 1 {
            return "1 release is blocked for this item."
        }
        return "\(entryCount) releases are blocked for this item."
    }
}

#if DEBUG
    #Preview("Entity Blocklist · Blocked Releases") {
        let entityID = EntityAcquisitionPanelPreviewFixtures.entityID
        let port = PreviewEntityAcquisitionService(
            snapshot: EntityAcquisitionPanelPreviewFixtures.downloadingState,
            blocklistEntries: [
                RequestActivityBlocklistEntry(
                    id: UUID(),
                    reason: RequestActivityBlocklistReason(rawValue: "failed"),
                    title: "Example.Release.WEB",
                    indexerName: "Example Indexer",
                    infoHash: nil,
                    acquisitionID: nil,
                    entityID: entityID,
                    entityKind: .book,
                    entityTitle: "Example",
                    message: "Download client was temporarily unavailable.",
                    createdAt: Date()
                )
            ]
        )
        EntityAcquisitionBlocklistSection(
            entityID: entityID,
            service: EntityAcquisitionService(port: port)
        )
        .padding()
    }
#endif
