import Foundation

struct SetupRequest: Encodable, Sendable {
    let username: String
    let password: String
    let displayName: String?
}
