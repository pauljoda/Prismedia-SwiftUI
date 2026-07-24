import Foundation

public struct AdministrativeSettingsValuesResponse: Decodable, Sendable {
    public let values: [String: AdministrativeJSONValue]

    public init(values: [String: AdministrativeJSONValue]) {
        self.values = values
    }
}
