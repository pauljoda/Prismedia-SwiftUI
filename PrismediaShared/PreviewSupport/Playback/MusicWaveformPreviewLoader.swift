import Foundation

public struct MusicWaveformPreviewLoader: MusicWaveformLoading {
    public static let waveform = MusicWaveform(
        samples: (0..<160).flatMap { index in
            let phase = Double(index) / 9
            let amplitude = 0.18 + (abs(sin(phase)) * 0.78)
            return [-amplitude, amplitude]
        }
    )

    public init() {}

    public func loadWaveform(for trackID: UUID) async throws -> MusicWaveform {
        Self.waveform
    }
}
