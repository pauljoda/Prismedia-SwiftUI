import Foundation

public struct RequestActivityTransfer: Decodable, Equatable, Sendable {
    public let progress: Double
    public let state: String?
    public let totalSizeBytes: Int64
    public let downloadSpeedBytesPerSecond: Double
    public let etaSeconds: Int64
    public let seeds: Int
    public let peers: Int
    public let savePath: String?
    public let pieceStates: [Int]

    private enum CodingKeys: String, CodingKey {
        case progress
        case state
        case totalSizeBytes
        case downloadSpeedBytesPerSecond
        case etaSeconds
        case seeds
        case peers
        case savePath
        case pieceStates
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        progress = try RequestActivityDecoding.double(from: container, forKey: .progress)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        totalSizeBytes = try RequestActivityDecoding.integer64(from: container, forKey: .totalSizeBytes)
        downloadSpeedBytesPerSecond = try RequestActivityDecoding.double(
            from: container,
            forKey: .downloadSpeedBytesPerSecond
        )
        etaSeconds = try RequestActivityDecoding.integer64(from: container, forKey: .etaSeconds)
        seeds = try RequestActivityDecoding.integer(from: container, forKey: .seeds)
        peers = try RequestActivityDecoding.integer(from: container, forKey: .peers)
        savePath = try container.decodeIfPresent(String.self, forKey: .savePath)
        var pieceContainer = try container.nestedUnkeyedContainer(forKey: .pieceStates)
        var pieces: [Int] = []
        while !pieceContainer.isAtEnd {
            if let value = try? pieceContainer.decode(Int.self) {
                pieces.append(value)
            } else {
                let value = try pieceContainer.decode(String.self)
                guard let parsed = Int(value) else {
                    throw DecodingError.dataCorruptedError(
                        in: pieceContainer, debugDescription: "Expected an integer piece state.")
                }
                pieces.append(parsed)
            }
        }
        pieceStates = pieces
    }
}
