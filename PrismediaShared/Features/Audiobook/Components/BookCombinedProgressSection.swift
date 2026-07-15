import SwiftUI

struct BookCombinedProgressSection: View {
    let presentation: BookCombinedProgressPresentation
    let readingErrorMessage: String?
    let listeningErrorMessage: String?
    let horizontalPadding: CGFloat
    let onContinueReading: () -> Void
    let onContinueListening: () -> Void
    let onContinueCombined: () -> Void
    let onStartReadingOver: () -> Void
    let onStartListeningOver: () -> Void
    let onToggleReadingCompletion: () -> Void
    let onToggleListeningCompletion: () -> Void
    let onDismissReadingError: () -> Void
    let onDismissListeningError: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
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
            BookCombinedProgressCard(
                presentation: presentation,
                onContinueReading: onContinueReading,
                onContinueListening: onContinueListening,
                onContinueCombined: onContinueCombined,
                onStartReadingOver: onStartReadingOver,
                onStartListeningOver: onStartListeningOver,
                onToggleReadingCompletion: onToggleReadingCompletion,
                onToggleListeningCompletion: onToggleListeningCompletion
            )
        }
        .padding(.horizontal, horizontalPadding)
    }
}

#if DEBUG
    #Preview("Combined Progress Section · Errors") {
        PreviewShell {
            BookCombinedProgressSection(
                presentation: BookCombinedProgressPresentation(
                    reading: ReadingProgressPresentation(
                        singleFileProgress: EntityProgressCapability(
                            currentEntityID: UUID(), unit: .cfi, index: 5_000, total: 10_000,
                            mode: .paged, completedAt: nil, updatedAt: nil, workIndex: nil,
                            workTotal: nil, location: "Text/chapter-5.xhtml"
                        )
                    ),
                    listening: AudiobookPlaybackPresentation(
                        totalDuration: 36_000, partCount: 12, resumeSeconds: 12_400,
                        isCompleted: false, isCurrentAudiobook: false, isPlaying: false
                    ),
                    combinedUsesReadingPosition: true,
                    isBusy: false
                ),
                readingErrorMessage: "Reading progress could not be updated.",
                listeningErrorMessage: nil,
                horizontalPadding: PrismediaSpacing.extraLarge,
                onContinueReading: {}, onContinueListening: {}, onContinueCombined: {},
                onStartReadingOver: {}, onStartListeningOver: {},
                onToggleReadingCompletion: {}, onToggleListeningCompletion: {},
                onDismissReadingError: {}, onDismissListeningError: {}
            )
        }
    }
#endif
