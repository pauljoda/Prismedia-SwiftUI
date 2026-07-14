import SwiftUI

public protocol TVHomeLoading: Sendable {
    func load(shelf: TVHomeShelf) async throws -> [EntityThumbnail]
}
