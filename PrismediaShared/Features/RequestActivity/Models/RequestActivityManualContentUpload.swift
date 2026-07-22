import Foundation

public struct RequestActivityManualContentUpload: Equatable, Sendable {
    public let entityID: UUID
    public let files: [RequestActivityManualUploadFile]

    public init(entityID: UUID, files: [RequestActivityManualUploadFile]) {
        self.entityID = entityID
        self.files = files
    }
}
