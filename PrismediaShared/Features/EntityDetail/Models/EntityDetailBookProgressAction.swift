enum EntityDetailBookProgressAction {
    case continueReading
    case resumeReading
    case continueListening
    case continueCombined
    case startReadingOver
    case startListeningOver
    case toggleReadingCompletion
    case toggleListeningCompletion
    case dismissReadingError
    case dismissListeningError
    case retryReading
    case readChapter(BookChapterMapping)
    case listenToChapter(BookChapterMapping)
    case combineChapter(BookChapterMapping)
    case retryChapters
}
