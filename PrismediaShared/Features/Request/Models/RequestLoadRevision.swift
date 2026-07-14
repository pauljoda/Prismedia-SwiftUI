import Foundation

public struct RequestLoadRevision: Hashable, Sendable {
    public private(set) var value = 0

    public init() {}

    @discardableResult
    public mutating func advance() -> Int {
        value += 1
        return value
    }

    public func isCurrent(_ candidate: Int) -> Bool { candidate == value }
}
