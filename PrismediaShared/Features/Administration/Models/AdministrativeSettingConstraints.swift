import Foundation

public struct AdministrativeSettingConstraints: Decodable, Hashable, Sendable {
    public let minimum: Double?
    public let maximum: Double?
    public let step: Double?
    public let minItems: Int?
    public let maxItems: Int?

    enum CodingKeys: String, CodingKey {
        case minimum = "min"
        case maximum = "max"
        case step, minItems, maxItems
    }
}
