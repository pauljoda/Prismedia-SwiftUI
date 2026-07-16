import Foundation

#if DEBUG
    struct AccountPreviewService: AccountServicing {
        func updateProfile(displayName: String) async throws -> UserAccount { PrismediaPreviewData.user }
        func changePassword(currentPassword: String, newPassword: String) async throws {}
        func sessions() async throws -> [AccountSession] {
            [
                AccountSession(
                    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    client: "Prismedia iOS",
                    deviceName: "Paul’s iPhone",
                    deviceID: "preview-device",
                    applicationVersion: "1.0",
                    createdAt: Date(timeIntervalSince1970: 1_751_328_000),
                    lastSeenAt: Date(timeIntervalSince1970: 1_752_033_600),
                    isCurrent: true
                ),
                AccountSession(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    client: "Safari",
                    deviceName: "MacBook Pro",
                    applicationVersion: "18.5",
                    createdAt: Date(timeIntervalSince1970: 1_749_600_000),
                    lastSeenAt: Date(timeIntervalSince1970: 1_751_947_200),
                    isCurrent: false
                ),
            ]
        }
        func revoke(sessionID: UUID) async throws {}
    }
#endif
