import SwiftUI

/// Inline recovery that leaves surrounding content and navigation available.
struct PrismediaRetryView: View {
    let title: String
    let message: String
    var isRetrying = false
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Label(title, systemImage: "exclamationmark.circle").font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PrismediaButton("Retry", systemImage: "arrow.clockwise", isLoading: isRetrying, action: retry)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
