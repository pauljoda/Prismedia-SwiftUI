import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityHistoryRow: View {
        let entry: RequestActivityHistoryEntry
        let referenceDate: Date
        let onOpenEntity: (RequestActivityHistoryEntry) -> Void

        var body: some View {
            Button {
                if entry.entityID != nil { onOpenEntity(entry) }
            } label: {
                HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                    Image(systemName: RequestActivityHistoryPolicy.systemImage(for: entry.event))
                        .foregroundStyle(RequestActivityHistoryPolicy.tone(for: entry.event).foregroundStyle)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) { heading }
                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) { heading }
                        }
                        if !metadata.isEmpty {
                            Text(metadata.joined(separator: " · "))
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
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(entry.entityID == nil)
            .accessibilityIdentifier("request-activity.history.\(entry.id.uuidString)")
        }

        @ViewBuilder
        private var heading: some View {
            Text(RequestActivityHistoryPolicy.label(for: entry.event))
                .font(.caption.weight(.semibold))
                .foregroundStyle(RequestActivityHistoryPolicy.tone(for: entry.event).foregroundStyle)
            Text(entry.kind.displayLabel)
                .font(.caption)
                .foregroundStyle(PrismediaColor.textMuted)
            Text(entry.title)
                .font(.headline)
                .foregroundStyle(PrismediaColor.textPrimary)
            Text(RequestActivityFormatting.relative(entry.createdAt, referenceDate: referenceDate))
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)
        }

        private var metadata: [String] {
            var values: [String] = []
            if let releaseTitle = entry.releaseTitle { values.append(releaseTitle) }
            if let qualityCode = entry.qualityCode { values.append(qualityCode) }
            if let indexerName = entry.indexerName { values.append("via \(indexerName)") }
            if let clientName = entry.downloadClientName { values.append("to \(clientName)") }
            return values
        }
    }

    #if DEBUG
        #Preview("Request Activity History") {
            RequestActivityHistoryRow(
                entry: RequestActivityPreviewFixtures.historyEntry,
                referenceDate: RequestActivityPreviewFixtures.referenceDate,
                onOpenEntity: { _ in }
            )
            .padding()
        }
    #endif
#endif
