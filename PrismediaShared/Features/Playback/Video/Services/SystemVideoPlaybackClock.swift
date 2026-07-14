import Foundation

struct SystemVideoPlaybackClock: VideoPlaybackClock {
    var now: TimeInterval { ProcessInfo.processInfo.systemUptime }
}
