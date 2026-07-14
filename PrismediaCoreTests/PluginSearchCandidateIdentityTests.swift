import XCTest

@testable import PrismediaCore

final class PluginSearchCandidateIdentityTests: XCTestCase {
    func testExternalIdentityIsStableAcrossDictionaryOrdering() {
        let first = candidate(externalIDs: ["tmdb": "42", "imdb": "tt42"])
        let second = candidate(externalIDs: ["imdb": "tt42", "tmdb": "42"])

        XCTAssertEqual(
            PluginSearchCandidateIdentity(candidate: first),
            PluginSearchCandidateIdentity(candidate: second)
        )
    }

    func testProviderScopesCandidateOwnedIdentity() {
        let first = candidate(externalIDs: [:], candidateID: "42", source: "tmdb")
        let second = candidate(externalIDs: [:], candidateID: "42", source: "openlibrary")

        XCTAssertNotEqual(
            PluginSearchCandidateIdentity(candidate: first),
            PluginSearchCandidateIdentity(candidate: second)
        )
    }

    func testFallbackIdentityRemainsDeterministicWithoutProviderIDs() {
        let first = candidate(externalIDs: [:], candidateID: nil, source: nil)
        let second = candidate(externalIDs: [:], candidateID: nil, source: nil)

        XCTAssertEqual(
            PluginSearchCandidateIdentity(candidate: first),
            PluginSearchCandidateIdentity(candidate: second)
        )
    }

    private func candidate(
        externalIDs: [String: String],
        candidateID: String? = nil,
        source: String? = "provider"
    ) -> AdministrativeEntitySearchCandidate {
        AdministrativeEntitySearchCandidate(
            externalIDs: externalIDs,
            title: "Arrival",
            year: 2016,
            posterURL: "https://images.example.test/arrival.jpg",
            candidateID: candidateID,
            source: source
        )
    }
}
