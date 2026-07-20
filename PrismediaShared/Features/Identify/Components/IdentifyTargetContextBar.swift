import SwiftUI

#if os(iOS) || os(macOS)
    /// Compact "To Identify" context bar showing which library item the current
    /// search or proposal applies to, mirroring the web target preview.
    struct IdentifyTargetContextBar: View {
        let item: AdministrativeIdentifyQueueItem

        var body: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Image(systemName: "scope")
                    .foregroundStyle(PrismediaColor.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("To Identify")
                        .font(.caption2.smallCaps().weight(.semibold))
                        .foregroundStyle(PrismediaColor.textMuted)
                    HStack(spacing: PrismediaSpacing.small) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text(item.entityKind.rawValue)
                            .font(.caption2.monospaced())
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
            }
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.vertical, PrismediaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .prismediaPanel()
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("identify.target-context")
        }

        private var statusLabel: String {
            let state = IdentifyQueueState(rawServerValue: item.state)
            switch state {
            case .proposal: return "match found"
            case .choice: return "awaiting match"
            case .queued, .searching: return "searching…"
            default: return state.label.lowercased()
            }
        }
    }

    #if DEBUG
        #Preview("Target Context Bar") {
            PreviewShell {
                IdentifyTargetContextBar(item: IdentifyPreviewFixtures.reviewItem)
                    .padding()
            }
        }
    #endif
#endif
