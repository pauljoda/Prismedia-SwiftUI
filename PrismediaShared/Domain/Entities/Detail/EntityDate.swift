import Foundation

public struct EntityDate: Decodable, Hashable, Sendable {
    public let code: String
    public let value: String
    public let sortableValue: String?
    public let precision: String?

    public var type: EntityDateType? { EntityDateType(metadataCode: code) }

    public init(
        code: String,
        value: String,
        sortableValue: String? = nil,
        precision: String? = nil
    ) {
        self.code = code
        self.value = value
        self.sortableValue = sortableValue
        self.precision = precision
    }
}
