import Foundation

/// An exact EPUB locator paired with the time it was last observed on this device.
public struct EPUBLocatorCheckpoint: Codable, Equatable, Sendable {
    public let locator: String
    public let savedAt: Date

    public init(locator: String, savedAt: Date) {
        self.locator = locator
        self.savedAt = savedAt
    }
}
