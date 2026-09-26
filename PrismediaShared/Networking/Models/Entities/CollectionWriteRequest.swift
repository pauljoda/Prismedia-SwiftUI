import Foundation

/// Body for `POST /api/collections`. Rule tree and cover fields are omitted, so the server applies its
/// defaults: no rules and a mosaic cover.
struct CollectionWriteRequest: Encodable, Sendable {
    let title: String
    let description: String?
    let mode: CollectionMode
    let isNsfw: Bool
    let isShared: Bool
}
