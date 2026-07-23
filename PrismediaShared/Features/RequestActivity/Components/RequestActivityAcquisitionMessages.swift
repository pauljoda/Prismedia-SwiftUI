import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityAcquisitionMessages: View {
        let actionErrorMessage: String?
        let canRetryAction: Bool
        let refreshMessage: String?
        let onRetryAction: () -> Void
        let onDismissAction: () -> Void
        let onRetryRefresh: () -> Void
        let onDismissRefresh: () -> Void

        @ViewBuilder
        var body: some View {
            if let actionErrorMessage {
                RequestActivityLifecycleMessage(
                    title: "Acquisition Action Failed",
                    message: actionErrorMessage,
                    retryTitle: canRetryAction ? "Retry" : nil,
                    onRetry: canRetryAction ? onRetryAction : nil,
                    onDismiss: onDismissAction
                )
            }

            if let refreshMessage {
                RequestActivityLifecycleMessage(
                    title: "Live Updates Delayed",
                    message: refreshMessage,
                    isWarning: true,
                    retryTitle: "Retry Now",
                    onRetry: onRetryRefresh,
                    onDismiss: onDismissRefresh
                )
            }
        }
    }

    #if DEBUG
        #Preview("Acquisition Messages · Error and Warning") {
            VStack(spacing: PrismediaSpacing.large) {
                RequestActivityAcquisitionMessages(
                    actionErrorMessage: "The server rejected the request.",
                    canRetryAction: true,
                    refreshMessage: "Live updates are temporarily delayed.",
                    onRetryAction: {},
                    onDismissAction: {},
                    onRetryRefresh: {},
                    onDismissRefresh: {}
                )
            }
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    #endif
#endif
