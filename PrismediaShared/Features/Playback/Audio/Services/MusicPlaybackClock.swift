import Foundation

protocol MusicPlaybackClock: Sendable {
    var now: TimeInterval { get }
}
