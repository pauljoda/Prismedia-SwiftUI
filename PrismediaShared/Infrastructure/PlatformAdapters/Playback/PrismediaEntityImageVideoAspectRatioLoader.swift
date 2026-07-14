import AVFoundation
import Foundation

public struct PrismediaEntityImageVideoAspectRatioLoader: EntityImageVideoAspectRatioLoading {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func loadVideoAspectRatio(path: String) async throws -> Double {
        guard let url = client.authenticatedMediaURL(for: path) else {
            throw URLError(.badURL)
        }

        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw URLError(.cannotDecodeContentData)
        }
        let naturalSize = try await track.load(.naturalSize)
        let preferredTransform = try await track.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let width = abs(transformedSize.width)
        let height = abs(transformedSize.height)
        guard width > 0, height > 0 else {
            throw URLError(.cannotDecodeContentData)
        }
        return Double(width / height)
    }
}
