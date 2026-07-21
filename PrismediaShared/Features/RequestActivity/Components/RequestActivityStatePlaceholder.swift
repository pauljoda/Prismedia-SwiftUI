import SwiftUI

#if os(iOS) || os(macOS)
    /// Compact busy/empty placeholder used by the embedded acquisition management
    /// sections (searching, preparing download, cleanup, no files yet).
    struct RequestActivityStatePlaceholder: View {
        let title: String
        let message: String
        let systemImage: String
        var isBusy: Bool = false

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: systemImage)
                        .foregroundStyle(PrismediaColor.textMuted)
                }
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PrismediaSpacing.medium)
            .prismediaPanel()
            .accessibilityElement(children: .combine)
        }
    }

    #if DEBUG
        #Preview("State Placeholder") {
            VStack(spacing: PrismediaSpacing.medium) {
                RequestActivityStatePlaceholder(
                    title: "Searching indexers",
                    message: "Querying your configured indexers for matching releases. This can take a moment.",
                    systemImage: "magnifyingglass",
                    isBusy: true
                )
                RequestActivityStatePlaceholder(
                    title: "No releases found",
                    message: "No indexer returned a matching release for this title.",
                    systemImage: "magnifyingglass"
                )
            }
            .padding()
        }
    #endif
#endif
