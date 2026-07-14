import Foundation

public enum TVPlaybackAction: Equatable, Sendable {
    case resume(seconds: Double)
    case play
    case playFromBeginning

    public var startSeconds: Double {
        switch self {
        case .resume(let seconds): max(0, seconds)
        case .play, .playFromBeginning: 0
        }
    }
}
