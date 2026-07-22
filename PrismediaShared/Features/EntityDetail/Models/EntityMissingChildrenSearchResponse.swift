import Foundation

public struct EntityMissingChildrenSearchResponse: Decodable, Equatable, Sendable {
    public let covered: Int
    public let missing: Int

    public init(covered: Int, missing: Int) {
        self.covered = covered
        self.missing = missing
    }
}
