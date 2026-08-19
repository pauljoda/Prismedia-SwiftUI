import Foundation

struct ReplaceBookChapterMappingsRequest: Encodable, Sendable {
    let mappings: [BookChapterAudioMapping]
}
