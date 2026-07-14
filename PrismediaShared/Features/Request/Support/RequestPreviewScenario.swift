import Foundation

#if DEBUG
    enum RequestPreviewScenario: Sendable {
        case content
        case loading
        case empty
        case error
    }
#endif
