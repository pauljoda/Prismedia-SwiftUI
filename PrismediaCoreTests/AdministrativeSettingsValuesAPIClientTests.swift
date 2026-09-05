import XCTest

@testable import PrismediaCore

final class AdministrativeSettingsValuesAPIClientTests: XCTestCase {
    func testProviderDefaultUpdateSendsAnObjectAndDecodesTheAcknowledgedMap() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"key":"identify.defaultProviders","groupKey":"identify","label":"Providers","description":"","type":"stringMap","value":{"movie":"tmdb","book":"unavailable"},"defaultValue":{},"isDefault":false,"order":0,"options":[]}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!, accessToken: "token", loader: loader)
        let values = [EntityKind.movie.rawValue: "tmdb", EntityKind.book.rawValue: "unavailable"]
        let acknowledged = try await client.updateAdministrativeSetting(
            key: PrismediaContractCodes.SettingKey.identifyDefaultProviders, value: .stringMap(values))
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/settings/identify.defaultProviders")
        XCTAssertEqual(request.httpMethod, "PATCH")
        let body = try JSONDecoder().decode([String: [String: String]].self, from: XCTUnwrap(request.httpBody))
        XCTAssertEqual(body["value"], values)
        XCTAssertEqual(acknowledged.value.stringMapValue, values)
    }

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
