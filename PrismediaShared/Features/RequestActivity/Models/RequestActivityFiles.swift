import Foundation

public struct RequestActivityFiles: Decodable, Equatable, Sendable {
    public let imported: Bool
    public let phase: RequestActivityImportPhase?
    public let files: [RequestActivityFile]
    public let importInformationUnavailable: Bool?

    public init(
        imported: Bool,
        phase: RequestActivityImportPhase? = nil,
        files: [RequestActivityFile],
        importInformationUnavailable: Bool? = nil
    ) {
        self.imported = imported
        self.phase = phase
        self.files = files
        self.importInformationUnavailable = importInformationUnavailable
    }
}
