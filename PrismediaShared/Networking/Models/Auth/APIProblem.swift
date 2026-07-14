import Foundation

public struct APIProblem: Decodable, Equatable, Sendable {
    public let code: String
    public let message: String
}
