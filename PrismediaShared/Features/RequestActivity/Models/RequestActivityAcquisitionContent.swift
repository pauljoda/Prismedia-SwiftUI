import Foundation

enum RequestActivityAcquisitionContent: Equatable, Sendable {
    case preparingSearch
    case searching
    case download
    case files
    case releases
    case lifecycleOnly
    case locked
}
