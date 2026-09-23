import Foundation

public struct BookChapterMappingsResponse: Codable, Equatable, Sendable {
    public let mappings: [BookChapterAudioMapping]
    public let audioChapters: [BookAudioChapter]

    public init(mappings: [BookChapterAudioMapping], audioChapters: [BookAudioChapter] = []) {
        self.mappings = mappings
        self.audioChapters = audioChapters
    }

    private enum CodingKeys: String, CodingKey { case mappings, audioChapters }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mappings = try container.decode([BookChapterAudioMapping].self, forKey: .mappings)
        audioChapters = try container.decodeIfPresent([BookAudioChapter].self, forKey: .audioChapters) ?? []
    }
}
