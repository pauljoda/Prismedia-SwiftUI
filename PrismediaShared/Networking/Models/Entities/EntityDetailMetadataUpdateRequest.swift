import Foundation

public struct EntityDetailMetadataUpdateRequest: Encodable, Hashable, Sendable {
    public let fields: [String]
    public let patch: EntityDetailMetadataPatch

    public init(fields: [String], patch: EntityDetailMetadataPatch) {
        self.fields = fields
        self.patch = patch
    }
}
