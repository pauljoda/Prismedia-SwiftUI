import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityLifecycleMessage: View {
        let title: String
        let message: String
        var isWarning = false
        var retryTitle: String?
        var onRetry: (() -> Void)?
        var onDismiss: (() -> Void)?

        var body: some View {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
                Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isWarning ? PrismediaColor.warning : PrismediaColor.destructive)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let retryTitle, let onRetry {
                        Button(retryTitle, action: onRetry)
                            .buttonStyle(.borderless)
                            .foregroundStyle(PrismediaColor.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let onDismiss {
                    Button("Dismiss", systemImage: "xmark", action: onDismiss)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }
            .padding(PrismediaSpacing.medium)
            .background(
                PrismediaColor.controlFill,
                in: PrismediaStableRoundedRectangle(cornerRadius: PrismediaRadius.control)
            )
            .accessibilityElement(children: .contain)
        }
    }

    #if DEBUG
        #Preview("Lifecycle Message") {
            RequestActivityLifecycleMessage(
                title: "Live Updates Delayed",
                message: "Prismedia will keep retrying in the background.",
                isWarning: true,
                retryTitle: "Retry Now",
                onRetry: {},
                onDismiss: {}
            )
            .padding()
        }
    #endif
#endif
