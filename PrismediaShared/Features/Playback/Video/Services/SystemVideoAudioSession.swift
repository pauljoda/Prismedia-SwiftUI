@preconcurrency import AVFoundation

actor SystemVideoAudioSession: VideoAudioSessionPreparing {
    func prepare() async throws {
        #if os(iOS) || os(tvOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
            if let channelCount = VideoAudioOutputChannelPolicy.preferredChannelCount(
                maximumAvailable: session.maximumOutputNumberOfChannels
            ) {
                try session.setPreferredOutputNumberOfChannels(channelCount)
            }
        #endif
    }
}
