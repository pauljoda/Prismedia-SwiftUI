import Foundation

enum EntityDetailPhase: Sendable {
    case loading
    case content(EntityDetail)
    case failure(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
