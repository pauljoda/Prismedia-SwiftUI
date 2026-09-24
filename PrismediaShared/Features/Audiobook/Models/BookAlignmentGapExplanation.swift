import Foundation

/// The user-facing explanation for each reason the server could not align a Book position, and for
/// each reason a Book keeps reading and listening Separate.
struct BookAlignmentGapExplanation: Sendable {
    // MARK: - Static Variables

    static let readableChapterUnpaired = Self(reason: .readableChapterUnpaired) { chapter in
        String(localized: "\(chapter) has no matching audiobook chapter.")
    }
    static let audioChapterUnpaired = Self(reason: .audioChapterUnpaired) { chapter in
        String(localized: "\(chapter) has no matching ebook chapter.")
    }
    static let readableChaptersUnavailable = Self(
        reason: .readableChaptersUnavailable,
        separately: {
            String(
                localized:
                    "This ebook has no chapter list to line up with the audiobook, so reading and listening are tracked separately."
            )
        },
        message: { _ in
            String(localized: "This ebook has no chapter list to line up with the audiobook.")
        }
    )
    static let positionOutsideChapters = Self(reason: .positionOutsideChapters) { _ in
        String(localized: "Your position is outside the chapters that line up.")
    }
    static let audioUnavailable = Self(bookReason: .audioUnavailable) {
        String(localized: "This Book has no playable audiobook, so reading and listening are tracked separately.")
    }
    static let audioUnstructured = Self(bookReason: .audioUnstructured) {
        String(localized: "This audiobook has no chapter markers, so reading and listening are tracked separately.")
    }
    static let audioInParts = Self(bookReason: .audioInParts) {
        String(
            localized:
                "This audiobook is split into parts rather than chapters, so reading and listening are tracked separately."
        )
    }
    static let noExactPairs = Self(bookReason: .noExactPairs) {
        String(
            localized:
                "No chapters are matched yet. Map them in Chapter Mapping to switch between reading and listening."
        )
    }
    static let all: [Self] = [
        readableChapterUnpaired,
        audioChapterUnpaired,
        readableChaptersUnavailable,
        positionOutsideChapters,
        audioUnavailable,
        audioUnstructured,
        audioInParts,
        noExactPairs,
    ]

    // MARK: - Variables

    let reason: BookAlignmentGapReason
    private let message: @Sendable (String) -> String
    /// Why the whole Book keeps reading and listening separate, for reasons that describe the Book.
    private let separateMessage: (@Sendable () -> String)?

    // MARK: - Initializers

    private init(
        reason: BookAlignmentGapReason,
        separately separateMessage: (@Sendable () -> String)? = nil,
        message: @escaping @Sendable (String) -> String
    ) {
        self.reason = reason
        self.separateMessage = separateMessage
        self.message = message
    }

    /// A reason that describes the whole Book, explained the same way for a gap and for Separate.
    private init(bookReason reason: BookAlignmentGapReason, message: @escaping @Sendable () -> String) {
        self.init(reason: reason, separately: message) { _ in message() }
    }

    // MARK: - Actions - Lookup

    /// The explanation for `reason`, or nil for reasons that need none (such as no position yet).
    static func explaining(_ reason: BookAlignmentGapReason) -> Self? {
        all.first { $0.reason == reason }
    }

    // MARK: - Actions - Text

    /// Explanation text naming the chapter that has no counterpart, when the server named one.
    func text(chapterTitle: String?) -> String {
        message(chapterTitle.map { "“\($0)”" } ?? String(localized: "This chapter"))
    }

    /// One line explaining why a Book keeps reading and listening separate. Reasons this client does
    /// not know yet get a general line.
    static func separateText(for reason: BookAlignmentGapReason?) -> String {
        reason.flatMap(explaining)?.separateMessage?()
            ?? String(localized: "Reading and listening are tracked separately.")
    }
}
