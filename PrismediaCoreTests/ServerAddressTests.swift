import XCTest

@testable import PrismediaCore

final class ServerAddressTests: XCTestCase {
    func testAddsHTTPWhenSchemeIsMissingForLocalhost() throws {
        let address = try ServerAddress(text: "localhost:8008/")
        XCTAssertEqual(address.url.absoluteString, "http://localhost:8008")
    }

    func testDefaultsSchemeLessPublicHostsToHTTPS() throws {
        let address = try ServerAddress(text: "media.example.test")
        XCTAssertEqual(address.url.absoluteString, "https://media.example.test")
    }

    func testDefaultsSchemeLessPrivateHostsToHTTP() throws {
        let address = try ServerAddress(text: "10.10.10.100:8008")
        XCTAssertEqual(address.url.absoluteString, "http://10.10.10.100:8008")
    }

    func testStripsQueryAndFragment() throws {
        let address = try ServerAddress(text: "https://media.example.test/base?x=1#frag")
        XCTAssertEqual(address.url.absoluteString, "https://media.example.test/base")
    }

    func testRejectsEmptyAndInvalidInput() {
        XCTAssertThrowsError(try ServerAddress(text: "   ")) { error in
            XCTAssertEqual(error as? ServerAddressError, .invalidURL)
        }
        XCTAssertThrowsError(try ServerAddress(text: "ftp://media.example.test")) { error in
            XCTAssertEqual(error as? ServerAddressError, .invalidURL)
        }
    }
}
