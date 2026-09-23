import Foundation

/// Confirmed server outcome for one Book format.
public struct AdministrativeBookRenditionCommitResult: Decodable, Hashable, Sendable {
    public let rendition: String
    public let item: AdministrativeRequestCommitItem?
    public let error: String?

    public init(rendition: String, item: AdministrativeRequestCommitItem?, error: String? = nil) {
        self.rendition = rendition
        self.item = item
        self.error = error
    }
}
