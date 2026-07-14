import Foundation

public struct EntitySubtitle: Decodable, Hashable, Sendable {
    public let id: String
    public let language: String
    public let label: String?
    public let format: String
    public let source: String
    public let storagePath: String
    public let sourceFormat: String
    public let sourcePath: String?
    public let isDefault: Bool
}
