import XCTest

@testable import PrismediaCore

final class VideoSubtitleSettingsAPIClientTests: XCTestCase {
    func testLoadsOnlySubtitleValuesFromTheNonAdministrativeEndpoint() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"values":{"subtitles.autoEnable":false,"subtitles.preferredLanguages":["en","eng"],"subtitles.style":"outline","subtitles.fontScale":1.25,"subtitles.positionPercent":88,"subtitles.opacity":0.9}}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let settings = try await client.videoSubtitleSettings()

        XCTAssertEqual(settings.appearance.style, .outline)
        XCTAssertEqual(settings.appearance.fontScale, 1.25)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/settings/values")
        let keys = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?
            .queryItems?
            .filter { $0.name == "keys" }
            .compactMap(\.value)
        XCTAssertEqual(
            Set(keys ?? []),
            Set([
                "subtitles.autoEnable",
                "subtitles.preferredLanguages",
                "subtitles.style",
                "subtitles.fontScale",
                "subtitles.positionPercent",
                "subtitles.opacity",
            ]))
    }
}
