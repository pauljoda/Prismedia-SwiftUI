import Foundation

/// The chapter-mapping editor's unsaved, person-confirmed pairs: at most one readable chapter per
/// audio chapter, each remembering how it was confirmed. A pair picked by hand is `manual`; a pair
/// from a reviewed "fill in order" is `ordered`. The server's automatic pairs never enter a draft,
/// so a save never sends one back (the server rejects them).
struct BookChapterMappingDraft: Equatable, Sendable {
    // MARK: - Variables

    /// Confirmed pairs keyed by their audio chapter's identity.
    private var pairsByAudioChapter: [String: BookChapterAudioMapping]

    var isEmpty: Bool {
        pairsByAudioChapter.isEmpty
    }

    var count: Int {
        pairsByAudioChapter.count
    }

    // MARK: - Initializers

    /// Seeds the draft from persisted pairs. Automatic pairs stay out; a pair without an origin (an
    /// older server) counts as picked by hand. When a list names the same audio chapter twice the
    /// first pair wins instead of trapping.
    init(persisted mappings: [BookChapterAudioMapping] = []) {
        pairsByAudioChapter = Dictionary(
            mappings.filter { !$0.isAutomatic }.map { ($0.audioChapterIdentity, $0.confirmed($0.origin ?? .manual)) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // MARK: - Actions - Reading

    /// The readable chapter paired with `audioChapter`, if any.
    func readableChapterKey(for audioChapter: BookAudioChapter) -> String? {
        pairsByAudioChapter[audioChapter.identity]?.readableChapterKey
    }

    /// How the pair for `audioChapter` was confirmed, if it is paired.
    func origin(for audioChapter: BookAudioChapter) -> BookChapterMappingOrigin? {
        pairsByAudioChapter[audioChapter.identity]?.origin
    }

    // MARK: - Actions - Editing

    /// Pairs `audioChapter` by hand with `readableChapterKey`, or unpairs it for nil. A readable
    /// chapter pairs with one audio chapter, so another audio chapter holding it lets it go.
    mutating func pick(_ readableChapterKey: String?, for audioChapter: BookAudioChapter) {
        guard let readableChapterKey else {
            pairsByAudioChapter.removeValue(forKey: audioChapter.identity)
            return
        }
        pairsByAudioChapter = pairsByAudioChapter.filter {
            $0.key == audioChapter.identity || $0.value.readableChapterKey != readableChapterKey
        }
        pairsByAudioChapter[audioChapter.identity] = BookChapterAudioMapping(
            readableChapterKey: readableChapterKey,
            audioTrackID: audioChapter.audioTrackID,
            origin: .manual,
            audioMarkerID: audioChapter.audioMarkerID
        )
    }

    /// Replaces the draft with an in-order fill the person reviewed pair by pair; every pair is
    /// remembered as filled in order.
    mutating func accept(filledInOrder mappings: [BookChapterAudioMapping]) {
        self = Self(persisted: mappings.map { $0.confirmed(.ordered) })
    }

    mutating func clear() {
        pairsByAudioChapter = [:]
    }

    // MARK: - Actions - Saving

    /// The complete save request in audio-chapter order: pairs for chapters the Book still has,
    /// each `manual` or `ordered`, never automatic.
    func mappings(orderedBy audioChapters: [BookAudioChapter]) -> [BookChapterAudioMapping] {
        audioChapters.compactMap { pairsByAudioChapter[$0.identity] }
    }

    /// A comparison key over pairs and their origins, so a change of provenance alone is unsaved.
    static func signature(_ mappings: [BookChapterAudioMapping]) -> String {
        mappings
            .map { "\($0.audioChapterIdentity):\($0.readableChapterKey):\($0.origin?.rawValue ?? "")" }
            .sorted()
            .joined(separator: "|")
    }
}
