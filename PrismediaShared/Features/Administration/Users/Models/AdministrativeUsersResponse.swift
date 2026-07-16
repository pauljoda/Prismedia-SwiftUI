import Foundation

struct AdministrativeUsersResponse: Decodable, Sendable {
    let items: [UserAccount]
}
