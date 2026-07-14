import Foundation

extension PrismediaEntityDetailLoader: EntityTranscriptSourceLoading {
    public func loadTranscriptSource(videoID: UUID, trackID: String) async throws -> Data {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        guard let encodedTrackID = trackID.addingPercentEncoding(withAllowedCharacters: allowed) else {
            throw PrismediaAPIError.invalidURL(trackID)
        }
        return try await client.mediaData(
            for: "/api/videos/\(videoID.uuidString.lowercased())/subtitles/\(encodedTrackID)"
        )
    }
}
