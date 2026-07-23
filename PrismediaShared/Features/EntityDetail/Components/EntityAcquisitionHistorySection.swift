import SwiftUI

#if os(iOS) || os(macOS)
    /// Collapsible durable activity log and entity-scoped blocklist recovery surface.
    /// The owning panel supplies history while the nested recovery control loads its count.
    struct EntityAcquisitionHistorySection: View {
        let entries: [RequestActivityHistoryEntry]
        let entityID: UUID
        let service: EntityAcquisitionService
        var referenceDate: Date = .now
        @State private var isExpanded = false

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    ForEach(entries) { entry in
                        historyRow(entry)
                    }
                    if !entries.isEmpty {
                        Divider()
                    }
                    EntityAcquisitionBlocklistSection(
                        entityID: entityID,
                        service: service
                    )
                }
                .padding(.top, PrismediaSpacing.small)
            } label: {
                HStack(spacing: PrismediaSpacing.small) {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(String(entries.count))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                }
                .accessibilityAddTraits(.isHeader)
            }
            .accessibilityIdentifier("entity-detail.acquisition.history")
        }

        private func historyRow(_ entry: RequestActivityHistoryEntry) -> some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                Image(systemName: RequestActivityHistoryPolicy.systemImage(for: entry.event))
                    .foregroundStyle(RequestActivityHistoryPolicy.tone(for: entry.event).foregroundStyle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                        Text(RequestActivityHistoryPolicy.label(for: entry.event))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                RequestActivityHistoryPolicy.tone(for: entry.event).foregroundStyle
                            )
                        Spacer(minLength: PrismediaSpacing.small)
                        Text(
                            RequestActivityFormatting.relative(
                                entry.createdAt,
                                referenceDate: referenceDate
                            )
                        )
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                    }
                    if !metadata(entry).isEmpty {
                        Text(metadata(entry).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                    if let message = entry.message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }

        private func metadata(_ entry: RequestActivityHistoryEntry) -> [String] {
            var values: [String] = []
            if let releaseTitle = entry.releaseTitle { values.append(releaseTitle) }
            if let qualityCode = entry.qualityCode { values.append(qualityCode) }
            if let indexerName = entry.indexerName { values.append("via \(indexerName)") }
            if let clientName = entry.downloadClientName { values.append("to \(clientName)") }
            return values
        }
    }

    #if DEBUG
        #Preview("Entity Acquisition History") {
            EntityAcquisitionHistorySection(
                entries: [RequestActivityPreviewFixtures.historyEntry],
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                service: EntityAcquisitionService(
                    port: PreviewEntityAcquisitionService(
                        snapshot: EntityAcquisitionPanelPreviewFixtures.downloadingState
                    )
                ),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
            .padding()
        }
    #endif
#endif
