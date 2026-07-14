import Foundation

public struct EntityMonitorStatus: RawRepresentable, Codable, Hashable, Sendable {
    public static let active = EntityMonitorStatus(rawValue: "active")
    public static let paused = EntityMonitorStatus(rawValue: "paused")
    public static let deletingFiles = EntityMonitorStatus(rawValue: "deleting-files")
    public static let stopping = EntityMonitorStatus(rawValue: "stopping")
    public static let fulfilled = EntityMonitorStatus(rawValue: "fulfilled")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
