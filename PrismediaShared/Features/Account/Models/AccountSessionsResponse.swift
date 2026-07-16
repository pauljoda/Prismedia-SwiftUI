import Foundation

struct AccountSessionsResponse: Decodable, Sendable {
    let items: [AccountSession]
}
