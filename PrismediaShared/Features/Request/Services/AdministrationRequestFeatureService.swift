import Foundation

public struct AdministrationRequestFeatureService: RequestFeatureServicing {
    private let administration: any AdministrationServicing

    public init(administration: any AdministrationServicing) {
        self.administration = administration
    }

    public func providers() async throws -> [AdministrativePlugin] {
        try await administration.plugins()
    }

    public func search(
        kind: String,
        pluginID: String,
        fields: [String: String]
    ) async throws -> AdministrativeRequestSearchResponse {
        try await administration.searchRequests(kind: kind, pluginID: pluginID, fields: fields)
    }

    public func review(
        kind: String,
        pluginID: String,
        externalIdentity: AdministrativeExternalIdentity
    ) async throws -> AdministrativeRequestReviewResponse {
        try await administration.reviewRequest(
            kind: kind,
            pluginID: pluginID,
            externalIdentity: externalIdentity
        )
    }

    public func commit(
        _ request: AdministrativeReviewedRequestCommitRequest
    ) async throws -> AdministrativeRequestCommitResponse {
        try await administration.commitReviewedRequest(request)
    }

    public func libraryRoots() async throws -> [AdministrativeLibraryRoot] {
        try await administration.libraryRoots()
    }

    public func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile] {
        try await administration.acquisitionProfiles()
    }
}
