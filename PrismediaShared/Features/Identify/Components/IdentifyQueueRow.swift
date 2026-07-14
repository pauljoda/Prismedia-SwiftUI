import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyQueueRow: View {
        let item: AdministrativeIdentifyQueueItem

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title).font(.headline).lineLimit(1)
                    Spacer()
                    Text(state.label).font(.caption.weight(.semibold)).foregroundStyle(
                        state == .error ? .red : PrismediaColor.textSecondary)
                }
                if let proposed = item.proposal?.patch.title, proposed != item.title {
                    Label(proposed, systemImage: "arrow.right").font(.subheadline).foregroundStyle(
                        PrismediaColor.textSecondary)
                }
                HStack(spacing: PrismediaSpacing.small) {
                    Text(item.entityKind.displayLabel)
                    if let provider = item.provider { Text(provider) }
                    if let confidence = item.proposal?.confidence {
                        Text("\(NSDecimalNumber(decimal: confidence).doubleValue * 100, specifier: "%.0f")%")
                    }
                    if item.isNsfw { Label("NSFW", systemImage: "exclamationmark.triangle.fill") }
                }
                .font(.caption)
                .foregroundStyle(PrismediaColor.textMuted)
                if let error = item.error { Text(error).font(.caption).foregroundStyle(PrismediaColor.destructive) }
            }
            .padding(.vertical, PrismediaSpacing.extraSmall)
            .contentShape(.rect)
            .accessibilityIdentifier("identify.queue-row")
        }

        private var state: IdentifyQueueState { .init(rawServerValue: item.state) }
    }

    #if DEBUG
        #Preview("Queue Row · Proposal") {
            List { IdentifyQueueRow(item: IdentifyPreviewFixtures.reviewItem) }
        }

        #Preview("Queue Row · Error") {
            List { IdentifyQueueRow(item: IdentifyPreviewFixtures.errorItem) }
        }
    #endif
#endif
