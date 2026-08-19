import Foundation

struct BookChapterMappingsResponse: Codable, Equatable, Sendable {
    let mappings: [BookChapterAudioMapping]
}
