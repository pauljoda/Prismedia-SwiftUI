import SwiftUI

struct EntityDetailBookProgressView: Equatable, View {
    let combinedProgress: BookCombinedProgressPresentation?
    let readingState: EntityDetailReadingState
    let audiobookPresentation: AudiobookPlaybackPresentation?
    let listeningErrorMessage: String?
    let chapters: [BookChapterMapping]
    let chaptersAreLoading: Bool
    let chaptersErrorMessage: String?
    let readingChapterProgressLabel: String?
    let listeningChapterProgressLabel: String?
    let horizontalPadding: CGFloat
    let onContinueReading: () -> Void
    let onResumeReading: () -> Void
    let onContinueListening: () -> Void
    let onContinueCombined: () -> Void
    let onStartReadingOver: () -> Void
    let onStartListeningOver: () -> Void
    let onToggleReadingCompletion: () -> Void
    let onToggleListeningCompletion: () -> Void
    let onDismissReadingError: () -> Void
    let onDismissListeningError: () -> Void
    let onRetryReading: () -> Void
    let onReadChapter: (BookChapterMapping) -> Void
    let onListenToChapter: (BookChapterMapping) -> Void
    let onCombineChapter: (BookChapterMapping) -> Void
    let onRetryChapters: () -> Void

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.combinedProgress == rhs.combinedProgress
            && lhs.readingState == rhs.readingState
            && lhs.audiobookPresentation == rhs.audiobookPresentation
            && lhs.listeningErrorMessage == rhs.listeningErrorMessage
            && lhs.chapters == rhs.chapters
            && lhs.chaptersAreLoading == rhs.chaptersAreLoading
            && lhs.chaptersErrorMessage == rhs.chaptersErrorMessage
            && lhs.readingChapterProgressLabel == rhs.readingChapterProgressLabel
            && lhs.listeningChapterProgressLabel == rhs.listeningChapterProgressLabel
            && lhs.horizontalPadding == rhs.horizontalPadding
    }

    var body: some View {
        Group {
            if let combinedProgress {
                BookCombinedProgressSection(
                    presentation: combinedProgress,
                    readingErrorMessage: readingState.errorMessage,
                    listeningErrorMessage: listeningErrorMessage,
                    horizontalPadding: horizontalPadding,
                    onContinueReading: onContinueReading,
                    onContinueListening: onContinueListening,
                    onContinueCombined: onContinueCombined,
                    onStartReadingOver: onStartReadingOver,
                    onStartListeningOver: onStartListeningOver,
                    onToggleReadingCompletion: onToggleReadingCompletion,
                    onToggleListeningCompletion: onToggleListeningCompletion,
                    onDismissReadingError: onDismissReadingError,
                    onDismissListeningError: onDismissListeningError
                )
            } else {
                EntityDetailReadingSection(
                    state: readingState,
                    horizontalPadding: horizontalPadding,
                    onResume: onResumeReading,
                    onStartOver: onStartReadingOver,
                    onToggleCompletion: { _ in onToggleReadingCompletion() },
                    onRetry: onRetryReading,
                    onDismissError: onDismissReadingError
                )

                AudiobookDetailPlaybackSection(
                    presentation: audiobookPresentation,
                    errorMessage: listeningErrorMessage,
                    horizontalPadding: horizontalPadding,
                    onResume: onContinueListening,
                    onStartOver: onStartListeningOver,
                    onToggleCompletion: onToggleListeningCompletion,
                    onDismissError: onDismissListeningError
                )
            }

            BookChapterListSection(
                chapters: chapters,
                isLoading: chaptersAreLoading,
                errorMessage: chaptersErrorMessage,
                readingProgressLabel: readingChapterProgressLabel,
                listeningProgressLabel: listeningChapterProgressLabel,
                horizontalPadding: horizontalPadding,
                onRead: onReadChapter,
                onListen: onListenToChapter,
                onCombined: onCombineChapter,
                onRetry: onRetryChapters
            )
        }
    }
}

#if DEBUG
    #Preview("Book Progress · Listening and Chapters") {
        ScrollView {
            EntityDetailBookProgressView(
                combinedProgress: nil,
                readingState: EntityDetailReadingState(),
                audiobookPresentation: AudiobookPlaybackPresentation(
                    totalDuration: 36_300,
                    partCount: 12,
                    resumeSeconds: 12_420,
                    isCompleted: false,
                    isCurrentAudiobook: false,
                    isPlaying: false
                ),
                listeningErrorMessage: nil,
                chapters: [
                    BookChapterMapping(
                        id: "chapter-1",
                        title: "Chapter 1: A New Beginning",
                        order: 0,
                        depth: 0,
                        readTarget: .epub(location: "Text/chapter-1.xhtml"),
                        audioTrack: MusicTrack(
                            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                            title: "Chapter 1"
                        ),
                        isCurrentReading: true,
                        isCurrentAudio: true
                    )
                ],
                chaptersAreLoading: false,
                chaptersErrorMessage: nil,
                readingChapterProgressLabel: "42% read",
                listeningChapterProgressLabel: "1:12:08 of 8:43:19",
                horizontalPadding: PrismediaSpacing.extraLarge,
                onContinueReading: {},
                onResumeReading: {},
                onContinueListening: {},
                onContinueCombined: {},
                onStartReadingOver: {},
                onStartListeningOver: {},
                onToggleReadingCompletion: {},
                onToggleListeningCompletion: {},
                onDismissReadingError: {},
                onDismissListeningError: {},
                onRetryReading: {},
                onReadChapter: { _ in },
                onListenToChapter: { _ in },
                onCombineChapter: { _ in },
                onRetryChapters: {}
            )
            .padding(.vertical, PrismediaSpacing.extraLarge)
        }
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
