import Foundation

public protocol RequestFeatureServicing: Sendable {
    func providers() async throws -> [AdministrativePlugin]
    func search(kind: String, pluginID: String, fields: [String: String], limit: Int?) async throws
        -> AdministrativeRequestSearchResponse
    func review(kind: String, pluginID: String, externalIdentity: AdministrativeExternalIdentity) async throws
        -> AdministrativeRequestReviewResponse
    func commit(_ request: AdministrativeReviewedRequestCommitRequest) async throws
        -> AdministrativeRequestCommitResponse
    func libraryRoots() async throws -> [AdministrativeLibraryRoot]
    func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile]
}
