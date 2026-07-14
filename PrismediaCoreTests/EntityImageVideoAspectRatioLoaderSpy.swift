import Foundation

@testable import PrismediaCore

actor EntityImageVideoAspectRatioLoaderSpy: EntityImageVideoAspectRatioLoading {
    private let aspectRatiosByPath: [String: Double]
    private var requestedPaths: [String] = []

    init(aspectRatiosByPath: [String: Double]) {
        self.aspectRatiosByPath = aspectRatiosByPath
    }

    func loadVideoAspectRatio(path: String) async throws -> Double {
        requestedPaths.append(path)
        guard let aspectRatio = aspectRatiosByPath[path] else {
            throw URLError(.cannotDecodeContentData)
        }
        return aspectRatio
    }

    func requests() -> [String] {
        requestedPaths
    }
}
