import Foundation

protocol VideoPlaybackClock: Sendable {
    var now: TimeInterval { get }
}
