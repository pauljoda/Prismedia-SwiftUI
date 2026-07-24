import XCTest

@testable import PrismediaCore

final class AdministrativeSettingsValuesAPIClientTests: XCTestCase {
    func testLoadsOnlyRequestedSettingValues() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"values":{"identify.defaultProviders":{"movie":"tmdb","book":"openlibrary"}}}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let response = try await client.loadAdministrativeSettingValues(
            keys: ["identify.defaultProviders"]
        )

        XCTAssertEqual(
            response.values["identify.defaultProviders"]?.stringMapValue,
            ["movie": "tmdb", "book": "openlibrary"]
        )
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/settings/values")
        XCTAssertEqual(
            URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?
                .queryItems?
                .filter { $0.name == "keys" }
                .compactMap(\.value),
            ["identify.defaultProviders"]
        )
    }
}
