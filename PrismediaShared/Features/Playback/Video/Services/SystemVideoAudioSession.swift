@preconcurrency import AVFoundation

actor SystemVideoAudioSession: VideoAudioSessionPreparing {
    func prepare() async throws {
        #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        #elseif os(tvOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        #endif
    }
}
