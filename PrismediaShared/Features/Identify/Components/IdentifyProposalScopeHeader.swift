import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyProposalScopeHeader: View {
        let parentTitle: String
        let siblingIndex: Int
        let siblingCount: Int
        let onOpenParent: () -> Void
        let onOpenPrevious: () -> Void
        let onOpenNext: () -> Void

        var body: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                Button(parentTitle, systemImage: "chevron.left", action: onOpenParent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if siblingCount > 1 {
                    Button(action: onOpenPrevious) {
                        Image(systemName: "chevron.up")
                    }
                    .accessibilityLabel("Previous sibling")
                    .disabled(siblingIndex <= 0)

                    Text("\(max(0, siblingIndex + 1)) of \(siblingCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textSecondary)

                    Button(action: onOpenNext) {
                        Image(systemName: "chevron.down")
                    }
                    .accessibilityLabel("Next sibling")
                    .disabled(siblingIndex >= siblingCount - 1)
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    #if DEBUG
        #Preview("Identify Proposal Scope") {
            IdentifyProposalScopeHeader(
                parentTitle: "MythBusters",
                siblingIndex: 0,
                siblingCount: 16,
                onOpenParent: {},
                onOpenPrevious: {},
                onOpenNext: {}
            )
            .padding()
        }
    #endif
#endif
