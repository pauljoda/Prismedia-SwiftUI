import Foundation

#if os(iOS) || os(macOS)
    enum RequestIdentifyFlowMode: Hashable, Sendable {
        case request
        case identify

        var title: String {
            switch self {
            case .request: "Request"
            case .identify: "Identify"
            }
        }
    }
#endif
