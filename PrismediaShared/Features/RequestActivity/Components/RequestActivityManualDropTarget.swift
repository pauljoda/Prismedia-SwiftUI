import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityManualDropTarget: View {
        let title: String
        let message: String
        let isDisabled: Bool
        let onDrop: ([URL]) -> Void

        var body: some View {
            VStack(spacing: PrismediaSpacing.small) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(PrismediaSpacing.medium)
            .background(PrismediaColor.groupedContentBackground.opacity(0.5))
            .clipShape(.rect(cornerRadius: PrismediaRadius.control))
            .overlay {
                RoundedRectangle(cornerRadius: PrismediaRadius.control)
                    .strokeBorder(PrismediaColor.borderSubtle, style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard !isDisabled, !urls.isEmpty else { return false }
                onDrop(urls)
                return true
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityHint("Use the Choose Files button if drag and drop is unavailable.")
        }
    }

    #if DEBUG
        #Preview("Manual Drop Target") {
            RequestActivityManualDropTarget(
                title: "Drop acquisition files",
                message: "Add one or more files. Folders are not accepted.",
                isDisabled: false,
                onDrop: { _ in }
            )
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
