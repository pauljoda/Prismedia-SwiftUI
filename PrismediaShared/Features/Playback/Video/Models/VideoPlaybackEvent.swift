import Foundation

public enum VideoPlaybackEvent: Hashable, Sendable {
    case started
    case progress
    case stopped
}
