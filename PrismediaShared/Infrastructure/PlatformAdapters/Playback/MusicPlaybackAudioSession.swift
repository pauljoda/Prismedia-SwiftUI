#if os(iOS)
    import AVFoundation

    actor MusicPlaybackAudioSession {
        func activate() {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
            } catch {
                #if DEBUG
                    print("Music audio session activation failed: \(error)")
                #endif
            }
        }
    }
#endif
