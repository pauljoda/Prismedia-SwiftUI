import Foundation

#if canImport(UIKit)
    import UIKit
#endif

/// Identifies this install in the server's sessions/devices list.
public struct ClientDeviceInfo: Sendable {
    public let client: String
    public let deviceName: String?
    public let deviceID: String?

    public init(client: String, deviceName: String?, deviceID: String?) {
        self.client = client
        self.deviceName = deviceName
        self.deviceID = deviceID
    }

    @MainActor
    public static var current: ClientDeviceInfo {
        #if os(iOS)
            ClientDeviceInfo(
                client: UIDevice.current.userInterfaceIdiom == .pad ? "Prismedia iPadOS" : "Prismedia iOS",
                deviceName: UIDevice.current.name,
                deviceID: deviceIdentifier()
            )
        #elseif os(tvOS)
            ClientDeviceInfo(
                client: "Prismedia tvOS",
                deviceName: UIDevice.current.name,
                deviceID: deviceIdentifier()
            )
        #else
            ClientDeviceInfo(
                client: "Prismedia macOS",
                deviceName: Host.current().localizedName,
                deviceID: deviceIdentifier()
            )
        #endif
    }

    /// Stable per-install identifier so repeat sign-ins reuse one device entry.
    @MainActor
    private static func deviceIdentifier() -> String {
        let key = "prismedia.device-identifier"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        #if canImport(UIKit)
            let identifier = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
            let identifier = UUID().uuidString
        #endif

        UserDefaults.standard.set(identifier, forKey: key)
        return identifier
    }
}
