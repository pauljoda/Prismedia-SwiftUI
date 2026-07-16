import Foundation

public struct AccountSession: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let client: String?
    public let deviceName: String?
    public let deviceID: String?
    public let applicationVersion: String?
    public let createdAt: Date
    public let lastSeenAt: Date
    public let isCurrent: Bool

    public init(
        id: UUID,
        client: String? = nil,
        deviceName: String? = nil,
        deviceID: String? = nil,
        applicationVersion: String? = nil,
        createdAt: Date,
        lastSeenAt: Date,
        isCurrent: Bool
    ) {
        self.id = id
        self.client = client
        self.deviceName = deviceName
        self.deviceID = deviceID
        self.applicationVersion = applicationVersion
        self.createdAt = createdAt
        self.lastSeenAt = lastSeenAt
        self.isCurrent = isCurrent
    }

    private enum CodingKeys: String, CodingKey {
        case id, client, deviceName, applicationVersion, createdAt, lastSeenAt, isCurrent
        case deviceID = "deviceId"
    }
}
