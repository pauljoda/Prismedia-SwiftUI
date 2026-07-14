import Foundation

public struct LoginResponse: Decodable, Equatable, Sendable {
    public let accessToken: String
    public let user: UserAccount
}
