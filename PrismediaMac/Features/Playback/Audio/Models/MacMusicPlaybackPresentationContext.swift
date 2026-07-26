#if os(macOS)
    import SwiftUI

    struct MacMusicPlaybackPresentationContext {
        let controller: MusicPlayerController
        let engine: AVPlayerAudioPlaybackEngine
        let waveform: MusicWaveform?
        let isInspectorPresented: Binding<Bool>
    }

    extension EnvironmentValues {
        @Entry var macMusicPlaybackPresentation: MacMusicPlaybackPresentationContext?
    }
#endif
