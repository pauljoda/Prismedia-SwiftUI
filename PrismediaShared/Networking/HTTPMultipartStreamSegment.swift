import Foundation

enum HTTPMultipartStreamSegment: Sendable {
    case data(Data)
    case file(URL, sizeBytes: Int64)

    var sizeBytes: Int64 {
        switch self {
        case .data(let data): Int64(data.count)
        case .file(_, let sizeBytes): sizeBytes
        }
    }
}
