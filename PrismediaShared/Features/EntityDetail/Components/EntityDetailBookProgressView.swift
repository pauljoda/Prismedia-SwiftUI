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
    let onAction: (EntityDetailBookProgressAction) -> Void

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
                    onContinueReading: { onAction(.continueReading) },
                    onContinueListening: { onAction(.continueListening) },
                    onContinueCombined: { onAction(.continueCombined) },
                    onStartReadingOver: { onAction(.startReadingOver) },
                    onStartListeningOver: { onAction(.startListeningOver) },
                    onToggleReadingCompletion: { onAction(.toggleReadingCompletion) },
                    onToggleListeningCompletion: { onAction(.toggleListeningCompletion) },
                    onDismissReadingError: { onAction(.dismissReadingError) },
                    onDismissListeningError: { onAction(.dismissListeningError) }
                )
            } else {
                EntityDetailReadingSection(
                    state: readingState,
                    horizontalPadding: horizontalPadding,
                    onResume: { onAction(.resumeReading) },
                    onStartOver: { onAction(.startReadingOver) },
                    onToggleCompletion: { _ in onAction(.toggleReadingCompletion) },
                    onRetry: { onAction(.retryReading) },
                    onDismissError: { onAction(.dismissReadingError) }
                )

                AudiobookDetailPlaybackSection(
                    presentation: audiobookPresentation,
                    errorMessage: listeningErrorMessage,
                    horizontalPadding: horizontalPadding,
                    onResume: { onAction(.continueListening) },
                    onStartOver: { onAction(.startListeningOver) },
                    onToggleCompletion: { onAction(.toggleListeningCompletion) },
                    onDismissError: { onAction(.dismissListeningError) }
                )
            }

            BookChapterListSection(
                chapters: chapters,
                isLoading: chaptersAreLoading,
                errorMessage: chaptersErrorMessage,
                readingProgressLabel: readingChapterProgressLabel,
                listeningProgressLabel: listeningChapterProgressLabel,
                horizontalPadding: horizontalPadding,
                onRead: { onAction(.readChapter($0)) },
                onListen: { onAction(.listenToChapter($0)) },
                onCombined: { onAction(.combineChapter($0)) },
                onRetry: { onAction(.retryChapters) }
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
                onAction: { _ in }
            )
            .padding(.vertical, PrismediaSpacing.extraLarge)
        }
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
