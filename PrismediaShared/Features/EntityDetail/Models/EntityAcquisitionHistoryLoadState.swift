import Foundation

enum EntityAcquisitionHistoryLoadState: Equatable, Sendable {
    case loading
    case loaded
    case failed(String)

    var hasLoaded: Bool {
        self == .loaded
    }
}
