@preconcurrency import AVFoundation

actor SystemVideoAudioSession: VideoAudioSessionPreparing {
    func prepare() async throws {
        #if os(iOS) || os(tvOS)
            let session = AVAudioSession.sharedInstance()
            #if os(tvOS)
                try session.setCategory(.playback, mode: .moviePlayback)
            #else
                try session.setCategory(
                    .playback,
                    mode: .moviePlayback,
                    policy: .longFormVideo
                )
            #endif
            try session.setSupportsMultichannelContent(true)
            try session.setActive(true)
            if let channelCount = VideoAudioOutputChannelPolicy.preferredChannelCount(
                maximumAvailable: session.maximumOutputNumberOfChannels
            ) {
                try session.setPreferredOutputNumberOfChannels(channelCount)
            }
        #endif
    }
}
