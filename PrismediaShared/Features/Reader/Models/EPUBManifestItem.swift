import Foundation

struct EPUBManifestItem: Equatable, Sendable {
    let id: String
    let href: String
    let mediaType: String
    let properties: Set<String>
}
