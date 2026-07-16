/// Display-only state for watch, reading, and audiobook progress on an entity detail page.
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
        kind: MediaProgressKind,
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

    init(
        videoProgress: VideoContainerProgressPresentation,
        isBusy: Bool = false,
        canMutate: Bool = true
    ) {
        self.init(
            kind: .watch,
            status: videoProgress.status,
            percent: videoProgress.percent,
            positionLabel: videoProgress.positionLabel,
            contextLabel: videoProgress.contextLabel,
            showsResume: videoProgress.canContinue,
            showsStartOver: canMutate,
            showsCompletionToggle: canMutate,
            isBusy: isBusy
        )
    }
}

extension MediaProgressCardPresentation {
    var statusTitle: String {
        switch (kind, status) {
        case (_, .notStarted): "Not Started"
        case (.watch, .inProgress): "Watching"
        case (.read, .inProgress): "Reading"
        case (.listen, .inProgress): "Listening"
        case (.watch, .completed): "Watched"
        case (.read, .completed): "Read"
        case (.listen, .completed): "Listened"
        }
    }

    var progressAccessibilityLabel: String {
        switch kind {
        case .watch: "Watch progress"
        case .read: "Reading progress"
        case .listen: "Listening progress"
        }
    }

    var resumeTitle: String {
        switch kind {
        case .watch: "Continue"
        case .read: "Continue Reading"
        case .listen: "Continue Listening"
        }
    }

    var resumeSystemImage: String {
        switch kind {
        case .watch: "play.fill"
        case .read: "book.fill"
        case .listen: "headphones"
        }
    }

    var resumeAccessibilityHint: String {
        switch kind {
        case .watch: "Continues with the current episode"
        case .read: "Continues reading from your saved position"
        case .listen: "Continues listening from your saved position"
        }
    }

    var startOverAccessibilityHint: String {
        switch kind {
        case .watch: "Restarts watching from the first episode"
        case .read: "Restarts reading from the beginning"
        case .listen: "Restarts listening from the beginning"
        }
    }

    var completionTitle: String {
        switch (kind, status == .completed) {
        case (.watch, false): "Mark Watched"
        case (.watch, true): "Mark Unwatched"
        case (.read, false): "Mark Read"
        case (.read, true): "Mark Unread"
        case (.listen, false): "Mark Listened"
        case (.listen, true): "Mark Unlistened"
        }
    }

    var completionAccessibilityHint: String {
        switch (kind, status == .completed) {
        case (.watch, false): "Marks this series or season as watched"
        case (.watch, true): "Removes the watched status"
        case (.read, false): "Marks this media as read"
        case (.read, true): "Removes the read status"
        case (.listen, false): "Marks this media as listened"
        case (.listen, true): "Removes the listened status"
        }
    }
}
