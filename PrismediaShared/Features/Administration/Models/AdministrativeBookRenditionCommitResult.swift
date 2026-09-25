import Foundation

/// Confirmed server outcome for one Book format. The rendition keeps an unknown future code as
/// sent so a new format never decodes as a known one.
public struct AdministrativeBookRenditionCommitResult: Decodable, Hashable, Sendable {
    public let rendition: EntityBookRendition
    public let item: AdministrativeRequestCommitItem?
    public let error: String?

    public init(rendition: EntityBookRendition, item: AdministrativeRequestCommitItem?, error: String? = nil) {
        self.rendition = rendition
        self.item = item
        self.error = error
    }
}
