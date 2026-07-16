public enum VideoPlaybackNegotiationMode: Equatable, Sendable {
    case automatic
    case directStream
    case transcode

    var allowsDirectPlay: Bool { self == .automatic }
    var allowsDirectStream: Bool { self != .transcode }
}
