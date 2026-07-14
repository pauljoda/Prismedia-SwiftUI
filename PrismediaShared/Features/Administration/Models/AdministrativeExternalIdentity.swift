import Foundation

public struct AdministrativeExternalIdentity: Codable, Hashable, Sendable {
    public let namespace: String
    public let value: String

    public init(namespace: String, value: String) {
        self.namespace = namespace
        self.value = value
    }
}
