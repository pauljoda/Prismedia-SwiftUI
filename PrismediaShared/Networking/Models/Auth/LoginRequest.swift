import Foundation

struct LoginRequest: Encodable, Sendable {
    let username: String
    let password: String
    let client: String?
    let deviceName: String?
    let deviceId: String?
}
