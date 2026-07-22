import SwiftUI

struct EntityAcquisitionMessageCard: View {
    let title: LocalizedStringKey
    let message: String
    let isWarning: Bool
    let isInformational: Bool
    let retryTitle: LocalizedStringKey?
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?

    init(
        title: LocalizedStringKey,
        message: String,
        isWarning: Bool = false,
        isInformational: Bool = false,
        retryTitle: LocalizedStringKey? = nil,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.isWarning = isWarning
        self.isInformational = isInformational
        self.retryTitle = retryTitle
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: messageSystemImage)
                .foregroundStyle(messageColor)
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
            in: RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous)
        )
        .accessibilityElement(children: .contain)
    }

    private var messageSystemImage: String {
        if isInformational { return "checkmark.circle.fill" }
        return isWarning ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill"
    }

    private var messageColor: Color {
        if isInformational { return PrismediaColor.info }
        return isWarning ? PrismediaColor.warning : PrismediaColor.destructive
    }
}

#if DEBUG
    #Preview("Acquisition Message Card") {
        EntityAcquisitionMessageCard(
            title: "Monitoring Updated",
            message: "The change was saved, but this page couldn’t refresh.",
            isWarning: true,
            retryTitle: "Refresh",
            onRetry: {},
            onDismiss: {}
        )
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
