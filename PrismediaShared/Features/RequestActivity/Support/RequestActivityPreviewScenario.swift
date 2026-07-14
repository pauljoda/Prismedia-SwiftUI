import Foundation

#if DEBUG
    enum RequestActivityPreviewScenario: Equatable, Sendable {
        case content
        case loading
        case empty
        case error
    }
#endif
