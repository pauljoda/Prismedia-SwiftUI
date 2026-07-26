import Foundation

public struct PrismediaMusicWaveformLoader: MusicWaveformLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func loadWaveform(for trackID: UUID) async throws -> MusicWaveform {
        if let waveformPath = await waveformPath(for: trackID),
            let waveform = try? await waveform(at: waveformPath)
        {
            return waveform
        }

        return try await waveform(
            at: "/assets/audio-tracks/\(trackID.uuidString.lowercased())/waveform.json"
        )
    }

    private func waveformPath(for trackID: UUID) async -> String? {
        guard let detail = try? await client.fetchEntity(id: trackID) else { return nil }
        return detail.capabilities.compactMap { capability -> [EntityFile]? in
            guard case .files(let files) = capability else { return nil }
            return files.items
        }
        .flatMap { $0 }
        .first { $0.role.caseInsensitiveCompare("waveform") == .orderedSame }?
        .path
    }

    private func waveform(at path: String) async throws -> MusicWaveform {
        try JSONDecoder().decode(
            MusicWaveform.self,
            from: await client.mediaData(for: path)
        )
    }
}
