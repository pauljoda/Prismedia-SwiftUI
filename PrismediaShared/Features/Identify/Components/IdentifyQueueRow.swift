import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyQueueRow: View {
        let item: AdministrativeIdentifyQueueItem

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text(item.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(state.label) · \(item.entityKind.displayLabel)")
                    .font(.subheadline)
                    .foregroundStyle(state == .error ? PrismediaColor.destructive : PrismediaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let proposed = item.proposal?.patch.title, proposed != item.title {
                    Label(proposed, systemImage: "arrow.right").font(.subheadline).foregroundStyle(
                        PrismediaColor.textSecondary)
                }
                if item.isNsfw {
                    Label("NSFW", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
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

        #Preview("Queue Row · Large Text") {
            List { IdentifyQueueRow(item: IdentifyPreviewFixtures.reviewItem) }
                .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
