import Foundation

public protocol MusicWaveformLoading: Sendable {
    func loadWaveform(for trackID: UUID) async throws -> MusicWaveform
}
