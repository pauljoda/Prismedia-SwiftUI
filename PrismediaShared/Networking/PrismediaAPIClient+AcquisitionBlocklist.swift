import Foundation

extension PrismediaAPIClient {
    public func clearAcquisitionBlocklist(
        entityID: UUID? = nil,
        createdAfter: Date? = nil
    ) async throws -> AcquisitionBlocklistClearResponse {
        var queryItems: [URLQueryItem] = []
        if let entityID {
            queryItems.append(
                URLQueryItem(name: "entityId", value: entityID.uuidString.lowercased())
            )
        }
        if let createdAfter {
            queryItems.append(
                URLQueryItem(name: "createdAfter", value: createdAfter.formatted(.iso8601))
            )
        }
        return try await send(
            AcquisitionBlocklistClearResponse.self,
            path: "/api/acquisitions/blocklist",
            method: "DELETE",
            queryItems: queryItems
        )
    }
}
