import Foundation

/// The user-facing explanation for each reason the server could not align a Book position.
struct BookAlignmentGapExplanation: Sendable {
    // MARK: - Static Variables

    static let readableChapterUnpaired = Self(reason: .readableChapterUnpaired) { chapter in
        String(localized: "\(chapter) has no matching audiobook chapter.")
    }
    static let audioChapterUnpaired = Self(reason: .audioChapterUnpaired) { chapter in
        String(localized: "\(chapter) has no matching ebook chapter.")
    }
    static let readableChaptersUnavailable = Self(reason: .readableChaptersUnavailable) { _ in
        String(localized: "This ebook has no chapter list to line up with the audiobook.")
    }
    static let positionOutsideChapters = Self(reason: .positionOutsideChapters) { _ in
        String(localized: "Your position is outside the chapters that line up.")
    }
    static let all: [Self] = [
        readableChapterUnpaired,
        audioChapterUnpaired,
        readableChaptersUnavailable,
        positionOutsideChapters,
    ]

    // MARK: - Variables

    let reason: BookAlignmentGapReason
    private let message: @Sendable (String) -> String

    // MARK: - Initializers

    private init(reason: BookAlignmentGapReason, message: @escaping @Sendable (String) -> String) {
        self.reason = reason
        self.message = message
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
}
