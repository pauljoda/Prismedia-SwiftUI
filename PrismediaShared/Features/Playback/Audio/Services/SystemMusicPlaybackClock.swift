import Foundation

struct SystemMusicPlaybackClock: MusicPlaybackClock {
    var now: TimeInterval { ProcessInfo.processInfo.systemUptime }
}
