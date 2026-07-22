import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityManualErrorMessage: View {
        let message: String

        var body: some View {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(PrismediaColor.destructive)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Manual acquisition error. \(message)")
        }
    }

    #if DEBUG
        #Preview("Manual Acquisition Error") {
            RequestActivityManualErrorMessage(
                message: "The selected file is not supported for this item."
            )
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
