import Foundation

/// Titles, hints, and availability of the Read & Listen card's continue actions.
struct BookCombinedProgressActions: Equatable, Sendable {
    // MARK: - Static Variables

    /// Plain continue actions, used when no server resume projection describes them.
    static let continueEach = Self(
        readingTitle: String(localized: "Continue Reading"),
        listeningTitle: String(localized: "Continue Listening"),
        combinedTitle: String(localized: "Continue Combined")
    )

    // MARK: - Variables

    let readingTitle: String
    /// Why reading opens where it does, when the position is estimated from listening.
    let readingHint: String?
    let listeningTitle: String
    /// Why listening starts where it does, when the position is estimated from reading.
    let listeningHint: String?
    let combinedTitle: String
    /// Why reading and listening together start where they do, or cannot start.
    let combinedExplanation: String?
    let isCombinedAvailable: Bool

    // MARK: - Initializers

    init(
        readingTitle: String,
        readingHint: String? = nil,
        listeningTitle: String,
        listeningHint: String? = nil,
        combinedTitle: String,
        combinedExplanation: String? = nil,
        isCombinedAvailable: Bool = true
    ) {
        self.readingTitle = readingTitle
        self.readingHint = readingHint
        self.listeningTitle = listeningTitle
        self.listeningHint = listeningHint
        self.combinedTitle = combinedTitle
        self.combinedExplanation = combinedExplanation
        self.isCombinedAvailable = isCombinedAvailable
    }

    /// Actions for the server's resume projection: exact positions continue as recorded, aligned
    /// positions are marked "≈" when estimated, and a gap is explained instead of substituting
    /// another chapter. A Book that keeps its formats Separate (`isLinked` false) resumes each only
    /// at its own exact position and never starts both together.
    init(resume: BookResumeProjection?, isCompleted: Bool, isLinked: Bool = true) {
        let alignedReading = isLinked ? resume?.switchToReading.aligned?.reading : nil
        let alignedListening = isLinked ? resume?.switchToListening.aligned?.listening : nil
        let combined = isLinked ? resume?.combined : nil

        if resume?.exactReading != nil {
            readingTitle = String(localized: "Continue Reading")
            readingHint = nil
        } else if alignedReading != nil {
            readingTitle =
                resume?.switchToReading.approximate == true
                ? String(localized: "Continue Reading ≈") : String(localized: "Continue Reading")
            readingHint = String(localized: "Reading estimated from where you stopped listening.")
        } else {
            readingTitle = isCompleted ? String(localized: "Read Again") : String(localized: "Start Reading")
            readingHint = nil
        }

        if resume?.exactListening != nil {
            listeningTitle = String(localized: "Continue Listening")
            listeningHint = nil
        } else if alignedListening != nil {
            listeningTitle =
                resume?.switchToListening.approximate == true
                ? String(localized: "Continue Listening ≈") : String(localized: "Continue Listening")
            listeningHint = String(localized: "Listening estimated from where you stopped reading.")
        } else {
            listeningTitle = isCompleted ? String(localized: "Listen Again") : String(localized: "Start Listening")
            listeningHint = nil
        }

        if let combined, combined.gap == nil {
            if combined.basis == .freshStart {
                combinedTitle = String(localized: "Start Both")
            } else {
                combinedTitle =
                    combined.approximate
                    ? String(localized: "Continue Both ≈") : String(localized: "Continue Both")
            }
            combinedExplanation = nil
            isCombinedAvailable = true
        } else {
            combinedTitle = String(localized: "Read & Listen")
            combinedExplanation = combined?.gapExplanation
            isCombinedAvailable = false
        }
    }
}
