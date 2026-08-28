import XCTest

@testable import PrismediaCore

final class RequestFeatureAPIClientTests: XCTestCase {
    func testRequestLibraryTargetsUseAccessibleSummaryEndpoint() async throws {
        let rootID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"[{"id":"\#(rootID)","label":"Movies","scanVideos":true,"scanImages":false,"scanAudio":false,"scanBooks":false,"isNsfw":false}]"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let roots = try await client.listRequestLibraryRoots()

        XCTAssertEqual(roots.map(\.id), [rootID])
        XCTAssertEqual(roots.map(\.label), ["Movies"])
        XCTAssertEqual(loader.requests.map(\.url?.path), ["/api/libraries/accessible"])
    }
}
