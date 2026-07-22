import Foundation

public struct RequestActivityFile: Decodable, Equatable, Sendable {
    public let id: String?
    public let name: String
    public let sizeBytes: Int64
    public let progress: Double
    public let sourceRelativePath: String?
    public let destinationRelativePath: String?
    public let role: RequestActivityFileRole?
    public let contentKind: RequestActivityFileContentKind?
    public let status: RequestActivityFileStatus?
    public let decision: RequestActivityFileDecision?
    public let technicalError: String?
    var stableID: String { id ?? "\(sourceRelativePath ?? name)|\(destinationRelativePath ?? "")" }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case sizeBytes
        case progress
        case sourceRelativePath
        case destinationRelativePath
        case role
        case contentKind
        case status
        case decision
        case technicalError
    }

    public init(
        id: String?, name: String, sizeBytes: Int64, progress: Double,
        sourceRelativePath: String?, destinationRelativePath: String?,
        role: RequestActivityFileRole?, contentKind: RequestActivityFileContentKind?,
        status: RequestActivityFileStatus?, decision: RequestActivityFileDecision?, technicalError: String?
    ) {
        self.id = id
        self.name = name
        self.sizeBytes = sizeBytes
        self.progress = progress
        self.sourceRelativePath = sourceRelativePath
        self.destinationRelativePath = destinationRelativePath
        self.role = role
        self.contentKind = contentKind
        self.status = status
        self.decision = decision
        self.technicalError = technicalError
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sizeBytes = try RequestActivityDecoding.integer64(from: container, forKey: .sizeBytes)
        progress = try RequestActivityDecoding.double(from: container, forKey: .progress)
        sourceRelativePath = try container.decodeIfPresent(String.self, forKey: .sourceRelativePath)
        destinationRelativePath = try container.decodeIfPresent(String.self, forKey: .destinationRelativePath)
        role = try container.decodeIfPresent(RequestActivityFileRole.self, forKey: .role)
        contentKind = try container.decodeIfPresent(RequestActivityFileContentKind.self, forKey: .contentKind)
        status = try container.decodeIfPresent(RequestActivityFileStatus.self, forKey: .status)
        decision = try container.decodeIfPresent(RequestActivityFileDecision.self, forKey: .decision)
        technicalError = try container.decodeIfPresent(String.self, forKey: .technicalError)
    }
}
