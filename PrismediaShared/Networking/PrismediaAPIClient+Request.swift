import Foundation

extension PrismediaAPIClient {
    /// Lists the enabled library roots the signed-in user may target with a request.
    public func listRequestLibraryRoots() async throws -> [RequestLibraryRoot] {
        try await send([RequestLibraryRoot].self, path: "/api/libraries/accessible")
    }
}
