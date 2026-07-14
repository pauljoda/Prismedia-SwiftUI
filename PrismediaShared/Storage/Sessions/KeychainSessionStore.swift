import Foundation
import Security

public final class KeychainSessionStore: SessionStoring {
    private let service: String
    private let account: String

    public init(
        service: String = "com.pauljoda.Prismedia.session",
        account: String = "default"
    ) {
        self.service = service
        self.account = account
    }

    public func load() async throws -> AuthSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainSessionStoreError.unhandledStatus(status)
        }

        guard let data = item as? Data else {
            throw KeychainSessionStoreError.invalidData
        }

        return try PrismediaJSON.decoder().decode(AuthSession.self, from: data)
    }

    public func save(_ session: AuthSession) async throws {
        let data = try PrismediaJSON.encoder().encode(session)
        var query = baseQuery()
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecSuccess {
            return
        }

        guard status == errSecItemNotFound else {
            throw KeychainSessionStoreError.unhandledStatus(status)
        }

        query[kSecValueData as String] = data
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainSessionStoreError.unhandledStatus(addStatus)
        }
    }

    public func clear() async throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainSessionStoreError.unhandledStatus(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
