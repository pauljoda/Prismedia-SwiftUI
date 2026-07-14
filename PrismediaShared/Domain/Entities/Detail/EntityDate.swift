import Foundation

public struct EntityDate: Decodable, Hashable, Sendable {
    public let code: String
    public let value: String
    public let sortableValue: String?
    public let precision: String?
}
