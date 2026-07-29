import SwiftUI

struct BookCombinedProgressSection: View {
    let presentation: BookCombinedProgressPresentation
    let readingErrorMessage: String?
    let listeningErrorMessage: String?
    let horizontalPadding: CGFloat
    let onContinueReading: () -> Void
    let onContinueListening: () -> Void
    let onContinueCombined: () -> Void
    let onStartOver: () -> Void
    let onToggleCompletion: () -> Void
    let onDismissReadingError: () -> Void
    let onDismissListeningError: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            BookCombinedProgressCard(
                presentation: presentation,
                onContinueReading: onContinueReading,
                onContinueListening: onContinueListening,
                onContinueCombined: onContinueCombined,
                onStartOver: onStartOver,
                onToggleCompletion: onToggleCompletion
            )
            if let readingErrorMessage {
                MediaProgressErrorBanner(
                    message: readingErrorMessage,
                    textColor: PrismediaColor.textSecondary,
                    accessibilityIdentifier: "entity-detail.reading-progress.error",
                    onDismiss: onDismissReadingError
                )
            }
            if let listeningErrorMessage {
                MediaProgressErrorBanner(
                    message: listeningErrorMessage,
                    textColor: PrismediaColor.textSecondary,
                    accessibilityIdentifier: "entity-detail.audiobook-progress.error",
                    onDismiss: onDismissListeningError
                )
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
}

#if DEBUG
    #Preview("Combined Progress Section · Errors") {
        PreviewShell {
            BookCombinedProgressSection(
                presentation: BookCombinedProgressPresentation(
                    progress: EntityProgressCapability(
                        currentEntityID: UUID(), unit: .cfi, index: 5_000, total: 10_000,
                        mode: .paged, completedAt: nil, updatedAt: nil, workIndex: nil,
                        workTotal: nil, location: "Text/chapter-5.xhtml"
                    ),
                    reading: nil,
                    activitySeconds: 7_420,
                    isLoading: false,
                    isBusy: false
                ),
                readingErrorMessage: "Reading progress could not be updated.",
                listeningErrorMessage: nil,
                horizontalPadding: PrismediaSpacing.extraLarge,
                onContinueReading: {}, onContinueListening: {}, onContinueCombined: {},
                onStartOver: {}, onToggleCompletion: {},
                onDismissReadingError: {}, onDismissListeningError: {}
            )
        }
    }
#endif
