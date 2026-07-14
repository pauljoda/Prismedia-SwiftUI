import Foundation

public struct RequestReviewSelection: Hashable, Sendable {
    public let mode: RequestReviewSelectionMode
    public let selectableIDs: Set<String>
    public let rootSelection: Set<String>
    public let children: [AdministrativeRequestReviewTarget]
}
