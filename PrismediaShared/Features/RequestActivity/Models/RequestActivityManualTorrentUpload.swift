import Foundation

public struct RequestActivityManualTorrentUpload: Equatable, Sendable {
    public let acquisitionID: UUID
    public let fileName: String
    public let data: Data

    public init(acquisitionID: UUID, fileName: String, data: Data) {
        self.acquisitionID = acquisitionID
        self.fileName = fileName
        self.data = data
    }
}
