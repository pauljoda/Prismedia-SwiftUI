#if os(macOS)
    import SwiftUI

    struct MacMusicPlaybackPresentationContext {
        let controller: MusicPlayerController
        let engine: AVPlayerAudioPlaybackEngine
        let waveform: MusicWaveform?
        let artworkNamespace: Namespace.ID
        let isInspectorPresented: Binding<Bool>
    }

    extension EnvironmentValues {
        @Entry var macMusicPlaybackPresentation: MacMusicPlaybackPresentationContext?
    }
#endif
