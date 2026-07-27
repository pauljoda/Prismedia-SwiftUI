import Foundation

public struct AdministrativeEntityMetadataDatePatch: Codable, Hashable, Sendable {
    public let type: EntityDateType
    public let value: String

    public init(type: EntityDateType, value: String) {
        self.type = type
        self.value = value
    }
}
