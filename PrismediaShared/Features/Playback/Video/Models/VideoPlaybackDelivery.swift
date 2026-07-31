import Foundation

public enum VideoPlaybackDelivery: Sendable, Equatable, Decodable {
    case direct
    case remux
    case transcode

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        switch code {
        case PrismediaContractCodes.VideoPlaybackMethod.direct:
            self = .direct
        case PrismediaContractCodes.VideoPlaybackMethod.remux:
            self = .remux
        case PrismediaContractCodes.VideoPlaybackMethod.transcode:
            self = .transcode
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown video playback method: \(code)"
            )
        }
    }
}
