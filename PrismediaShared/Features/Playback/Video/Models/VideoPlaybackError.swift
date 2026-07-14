import Foundation

public enum VideoPlaybackError: Error, LocalizedError {
    case noPlayableSource

    public var errorDescription: String? { "This video has no stream the device can play." }
}
