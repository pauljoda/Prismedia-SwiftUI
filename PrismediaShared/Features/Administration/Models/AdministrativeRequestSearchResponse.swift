import Foundation

public struct AdministrativeRequestSearchResponse: Decodable, Sendable {
    public let results: [AdministrativeRequestSearchResult]
    public let providerErrors: [AdministrativeRequestProviderError]
}
