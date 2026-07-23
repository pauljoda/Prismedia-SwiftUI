import SwiftUI

#if os(iOS) || os(macOS)
    struct EntityAcquisitionHistoryRow: View {
        let entry: RequestActivityHistoryEntry
        let referenceDate: Date

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                Image(systemName: RequestActivityHistoryPolicy.systemImage(for: entry.event))
                    .foregroundStyle(RequestActivityHistoryPolicy.tone(for: entry.event).foregroundStyle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    heading

                    if let releaseTitle = nonEmpty(entry.releaseTitle) {
                        Text(releaseTitle)
                            .font(.caption.monospaced())
                            .foregroundStyle(PrismediaColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }

                    if !details.isEmpty {
                        Text(details.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }

                    if let message = nonEmpty(entry.message) {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var heading: some View {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                    eventLabel
                    Spacer(minLength: PrismediaSpacing.small)
                    timestamp
                }

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    eventLabel
                    timestamp
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }

        private var eventLabel: some View {
            Text(RequestActivityHistoryPolicy.label(for: entry.event))
                .font(.caption.weight(.semibold))
                .foregroundStyle(RequestActivityHistoryPolicy.tone(for: entry.event).foregroundStyle)
        }

        private var timestamp: some View {
            RequestActivityHistoryTimestamp(
                date: entry.createdAt,
                referenceDate: referenceDate
            )
        }

        private var details: [String] {
            var values: [String] = []
            if let qualityCode = nonEmpty(entry.qualityCode) {
                values.append("Quality \(qualityCode)")
            }
            if let indexerName = nonEmpty(entry.indexerName) {
                values.append("via \(indexerName)")
            }
            if let clientName = nonEmpty(entry.downloadClientName) {
                values.append("to \(clientName)")
            }
            if let formatScore = entry.formatScore {
                values.append("Format score \(signed(formatScore))")
            }
            return values
        }

        private func nonEmpty(_ value: String?) -> String? {
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return value
        }

        private func signed(_ value: Int) -> String {
            value > 0 ? "+\(value.formatted())" : value.formatted()
        }
    }

    #if DEBUG
        #Preview("Acquisition Review · History · Row Component") {
            EntityAcquisitionHistoryRow(
                entry: RequestActivityPreviewFixtures.historyEntries[5],
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
            .padding(PrismediaSpacing.extraLarge)
            .frame(width: 390)
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
        }
    #endif
#endif
