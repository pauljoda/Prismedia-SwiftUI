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
        Group {
            if entryCount.map({ $0 > 0 }) == true || message != nil {
                Divider()
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    Label("Blocked Releases", systemImage: "nosign")
                        .font(.headline)

                    if let entryCount, entryCount > 0 {
                        Text(
                            entryCount == 1
                                ? "1 release is blocked for this item."
                                : "(entryCount) releases are blocked for this item."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Button(role: .destructive) {
                            confirmsClear = true
                        } label: {
                            HStack {
                                Label("Allow Blocked Releases Again", systemImage: "arrow.uturn.backward")
                                Spacer()
                                if isClearing { ProgressView() }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .disabled(isClearing)
                    }

                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
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
            // A blocklist read must not make the rest of the acquisition panel fail.
        }
    }

    private func clear() async {
        isClearing = true
        defer { isClearing = false }
        do {
            let removed = try await service.clearAcquisitionBlocklist(entityID: entityID)
            entryCount = 0
            message = removed == 1 ? "Allowed 1 release again." : "Allowed (removed) releases again."
        } catch {
            message = error.localizedDescription
        }
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
