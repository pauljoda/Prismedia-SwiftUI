import Foundation

public enum VideoPlaybackError: Error, LocalizedError {
    case noPlayableSource
    case videoOutputUnavailable

    public var errorDescription: String? {
        switch self {
        case .noPlayableSource: "This video has no stream the device can play."
        case .videoOutputUnavailable: "Playback started, but no video frame was rendered."
        }
    }
}
