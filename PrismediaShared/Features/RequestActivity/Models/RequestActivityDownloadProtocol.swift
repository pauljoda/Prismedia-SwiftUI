import Foundation

public struct RequestActivityDownloadProtocol: RawRepresentable, Codable, Hashable, Sendable {
    public static let torrent = RequestActivityDownloadProtocol(rawValue: "torrent")
    public static let usenet = RequestActivityDownloadProtocol(rawValue: "usenet")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
