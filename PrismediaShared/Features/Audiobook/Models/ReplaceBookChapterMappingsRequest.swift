import Foundation

/// The complete person-confirmed chapter map a save replaces (`PUT …/chapter-mappings`). Automatic
/// pairs are server-owned and rejected on save, so the request never carries one: it keeps only
/// pairs confirmed by hand (`manual`, the meaning of an absent origin) or by a reviewed in-order fill
/// (`ordered`).
struct ReplaceBookChapterMappingsRequest: Encodable, Sendable {
    // MARK: - Variables

    let mappings: [BookChapterAudioMapping]

    // MARK: - Initializers

    init(mappings: [BookChapterAudioMapping]) {
        self.mappings = mappings.filter { !$0.isAutomatic }
    }
}
