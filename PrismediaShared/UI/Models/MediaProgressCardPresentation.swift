/// Display-only state for a resumable piece of media.
///
/// The presentation intentionally uses media-neutral language so the same card
/// can represent a video, comic, book, chapter, or series.
public struct MediaProgressCardPresentation: Hashable, Sendable {
    public let kind: MediaProgressKind
    public let status: MediaProgressStatus
    public let percent: Int
    public let positionLabel: String?
    public let contextLabel: String?
    public let showsResume: Bool
    public let showsStartOver: Bool
    public let showsCompletionToggle: Bool
    public let isBusy: Bool

    public init(
        kind: MediaProgressKind = .watch,
        status: MediaProgressStatus,
        percent: Int,
        positionLabel: String? = nil,
        contextLabel: String? = nil,
        showsResume: Bool,
        showsStartOver: Bool,
        showsCompletionToggle: Bool,
        isBusy: Bool = false
    ) {
        self.kind = kind
        self.status = status
        self.percent = min(100, max(0, percent))
        self.positionLabel = positionLabel
        self.contextLabel = contextLabel
        self.showsResume = showsResume
        self.showsStartOver = showsStartOver
        self.showsCompletionToggle = showsCompletionToggle
        self.isBusy = isBusy
    }

    public init(readingProgress: ReadingProgressPresentation, isBusy: Bool = false) {
        self.init(
            kind: .read,
            status: readingProgress.status,
            percent: readingProgress.percent,
            positionLabel: readingProgress.positionLabel,
            contextLabel: readingProgress.contextLabel,
            showsResume: readingProgress.canResume,
            showsStartOver: readingProgress.canStartOver,
            showsCompletionToggle: true,
            isBusy: isBusy
        )
    }
}

extension MediaProgressCardPresentation {
    var progressHeading: String {
        return switch kind {
        case .watch: "Playback"
        case .read: "Reading"
        case .listen: "Listening"
        }
    }

    var statusTitle: String {
        switch status {
        case .notStarted:
            "Not Started"
        case .inProgress:
            switch kind {
            case .watch: "In Progress"
            case .read: "Reading"
            case .listen: "Listening"
            }
        case .completed:
            switch kind {
            case .watch: "Watched"
            case .read: "Read"
            case .listen: "Listened"
            }
        }
    }

    var statusSystemImage: String {
        switch status {
        case .notStarted:
            "circle"
        case .inProgress:
            switch kind {
            case .watch: "play.circle.fill"
            case .read: "bookmark.fill"
            case .listen: "waveform.circle.fill"
            }
        case .completed:
            "checkmark.circle.fill"
        }
    }

    var progressAccessibilityLabel: String {
        switch kind {
        case .watch: "Playback progress"
        case .read: "Reading progress"
        case .listen: "Listening progress"
        }
    }

    var resumeAction: MediaProgressCardActionPresentation? {
        guard showsResume else { return nil }

        return switch kind {
        case .watch:
            MediaProgressCardActionPresentation(
                title: "Resume",
                systemImage: "play.fill",
                accessibilityHint: "Continues playback from your saved position"
            )
        case .read:
            MediaProgressCardActionPresentation(
                title: "Continue Reading",
                systemImage: "book.fill",
                accessibilityHint: "Continues reading from your saved position"
            )
        case .listen:
            MediaProgressCardActionPresentation(
                title: "Continue Listening",
                systemImage: "headphones",
                accessibilityHint: "Continues listening from your saved position"
            )
        }
    }

    var startOverAction: MediaProgressCardActionPresentation? {
        guard showsStartOver else { return nil }

        return MediaProgressCardActionPresentation(
            title: "Start Over",
            systemImage: "arrow.counterclockwise",
            accessibilityHint: startOverAccessibilityHint
        )
    }

    var completionAction: MediaProgressCardActionPresentation? {
        guard showsCompletionToggle else { return nil }

        return MediaProgressCardActionPresentation(
            title: completionActionTitle,
            systemImage: status == .completed ? "circle" : "checkmark.circle",
            accessibilityHint: completionAccessibilityHint
        )
    }

    var hasVisibleAction: Bool {
        resumeAction != nil || startOverAction != nil || completionAction != nil
    }

    private var startOverAccessibilityHint: String {
        switch kind {
        case .watch: "Restarts playback from the beginning"
        case .read: "Restarts reading from the beginning"
        case .listen: "Restarts listening from the beginning"
        }
    }

    private var completionActionTitle: String {
        switch (kind, status == .completed) {
        case (.watch, false): "Mark Watched"
        case (.watch, true): "Mark Unwatched"
        case (.read, false): "Mark Read"
        case (.read, true): "Mark Unread"
        case (.listen, false): "Mark Listened"
        case (.listen, true): "Mark Unlistened"
        }
    }

    private var completionAccessibilityHint: String {
        switch (kind, status == .completed) {
        case (.watch, false): "Marks this media as watched"
        case (.watch, true): "Removes the watched status"
        case (.read, false): "Marks this media as read"
        case (.read, true): "Removes the read status"
        case (.listen, false): "Marks this media as listened"
        case (.listen, true): "Removes the listened status"
        }
    }
}
