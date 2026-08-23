import Foundation

struct BookContentsResponse: Decodable, Equatable, Sendable {
    let items: [BookContentsEntry]
}
