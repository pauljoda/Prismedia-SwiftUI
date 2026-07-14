import CoreGraphics
import Foundation

final class RemoteArtworkCache: @unchecked Sendable {
    private let dataStorage = NSCache<NSURL, NSData>()
    private let decodedLock = NSLock()
    private let decodedByteCostLimit: Int
    private var decodedImages: [String: CGImage] = [:]
    private var decodedCosts: [String: Int] = [:]
    private var decodedRecency: [String] = []
    private var decodedByteCost = 0

    init(countLimit: Int, decodedByteCostLimit: Int) {
        dataStorage.countLimit = countLimit
        self.decodedByteCostLimit = max(0, decodedByteCostLimit)
    }

    func data(for url: URL) -> Data? {
        dataStorage.object(forKey: url as NSURL).map { $0 as Data }
    }

    func store(_ data: Data, for url: URL) {
        dataStorage.setObject(data as NSData, forKey: url as NSURL)
    }

    func image(for url: URL, maxPixelSize: Int) -> CGImage? {
        let key = decodedKey(for: url, maxPixelSize: maxPixelSize)
        return decodedLock.withLock {
            guard let image = decodedImages[key] else { return nil }
            recordAccess(to: key)
            return image
        }
    }

    func store(_ image: CGImage, for url: URL, maxPixelSize: Int) {
        let key = decodedKey(for: url, maxPixelSize: maxPixelSize)
        let byteCost = image.bytesPerRow.multipliedReportingOverflow(by: image.height)
        guard !byteCost.overflow else { return }
        decodedLock.withLock {
            removeDecodedImage(for: key)
            guard byteCost.partialValue <= decodedByteCostLimit else { return }
            decodedImages[key] = image
            decodedCosts[key] = byteCost.partialValue
            decodedRecency.append(key)
            decodedByteCost += byteCost.partialValue
            evictDecodedImagesToBudget()
        }
    }

    private func decodedKey(for url: URL, maxPixelSize: Int) -> String {
        "\(maxPixelSize)|\(url.absoluteString)"
    }

    private func recordAccess(to key: String) {
        decodedRecency.removeAll { $0 == key }
        decodedRecency.append(key)
    }

    private func evictDecodedImagesToBudget() {
        while decodedByteCost > decodedByteCostLimit,
            let leastRecentKey = decodedRecency.first
        {
            removeDecodedImage(for: leastRecentKey)
        }
    }

    private func removeDecodedImage(for key: String) {
        decodedImages[key] = nil
        decodedByteCost -= decodedCosts.removeValue(forKey: key) ?? 0
        decodedRecency.removeAll { $0 == key }
    }
}
