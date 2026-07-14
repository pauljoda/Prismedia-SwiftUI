import SwiftUI

struct MediaProgressErrorBanner: View {
    let message: String
    let textColor: Color
    let accessibilityIdentifier: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(PrismediaColor.warning)
                .accessibilityHidden(true)

            Text(message)
                .font(.callout)
                .foregroundStyle(textColor)

            Spacer(minLength: 8)

            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
        }
        .padding(PrismediaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#if DEBUG
    #Preview("Media Progress Error") {
        MediaProgressErrorBanner(
            message: "Progress could not be updated.",
            textColor: PrismediaColor.textPrimary,
            accessibilityIdentifier: "preview-progress-error",
            onDismiss: {}
        )
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
