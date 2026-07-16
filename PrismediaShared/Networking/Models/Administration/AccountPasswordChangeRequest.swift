import Foundation

struct AccountPasswordChangeRequest: Encodable, Sendable {
    let currentPassword: String
    let newPassword: String
}
