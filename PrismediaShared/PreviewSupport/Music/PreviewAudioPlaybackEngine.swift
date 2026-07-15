#if DEBUG
    import Foundation

    @MainActor
    final class PreviewAudioPlaybackEngine: AudioPlaybackEngine {
        func load(url: URL) {}
        func play() {}
        func pause() {}
        func seek(to seconds: Double) {}
        func setPlaybackRate(_ rate: Float) {}
    }
#endif
