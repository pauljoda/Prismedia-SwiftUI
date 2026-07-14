import Foundation
import ImageIO
import Observation

/// A narrowly-scoped observable cache. Views observe decoded page availability;
/// transport, task coalescing, and raw bytes remain implementation details.
@MainActor
@Observable
final class BookReaderPageCache {
    private(set) var images: [UUID: PlatformReaderImage] = [:]

    @ObservationIgnored private let service: any BookReaderServicing
    @ObservationIgnored private let maximumPixelSize: Int
    @ObservationIgnored private let decoder: @Sendable (Data, Int) -> PlatformReaderImage?
    @ObservationIgnored private var values: [UUID: Data] = [:]
    @ObservationIgnored private var retainedPageIDs: Set<UUID>?
    @ObservationIgnored private var tasks:
        [UUID: (token: UUID, task: Task<(data: Data, image: PlatformReaderImage), Error>)] = [:]

    convenience init(
        service: any BookReaderServicing,
        maximumPixelSize: Int = 4_096
    ) {
        self.init(
            service: service,
            maximumPixelSize: maximumPixelSize
        ) { data, maximumPixelSize in
            BookReaderPageCache.decodeImage(
                data,
                maximumPixelSize: maximumPixelSize
            )
        }
    }

    init(
        service: any BookReaderServicing,
        maximumPixelSize: Int = 4_096,
        decoder: @escaping @Sendable (Data, Int) -> PlatformReaderImage?
    ) {
        self.service = service
        self.maximumPixelSize = maximumPixelSize
        self.decoder = decoder
    }

    func data(for id: UUID) async throws -> Data {
        if let value = values[id], images[id] != nil { return value }

        let request = task(for: id)
        do {
            let decoded = try await request.task.value
            if let cachedValue = values[id], images[id] != nil { return cachedValue }
            guard tasks[id]?.token == request.token else {
                throw CancellationError()
            }

            tasks[id] = nil
            if retainedPageIDs?.contains(id) != false {
                values[id] = decoded.data
                images[id] = decoded.image
            }
            return decoded.data
        } catch {
            if tasks[id]?.token == request.token {
                tasks[id] = nil
            }
            throw error
        }
    }

    func retainOnly(_ pageIDs: Set<UUID>) {
        retainedPageIDs = pageIDs
        values = values.filter { pageIDs.contains($0.key) }
        images = images.filter { pageIDs.contains($0.key) }

        let discardedIDs = tasks.keys.filter { !pageIDs.contains($0) }
        for id in discardedIDs {
            tasks[id]?.task.cancel()
            tasks[id] = nil
        }
    }

    private func task(
        for id: UUID
    ) -> (token: UUID, task: Task<(data: Data, image: PlatformReaderImage), Error>) {
        if let request = tasks[id] { return request }
        let token = UUID()
        let service = service
        let decoder = decoder
        let maximumPixelSize = maximumPixelSize
        let task = Task {
            let data = try await service.loadPageData(id: id)
            try Task.checkCancellation()
            let image = await Task.detached(priority: .userInitiated) {
                decoder(data, maximumPixelSize)
            }.value
            guard let image else {
                throw BookReaderPageCacheError.imageDecodingFailed
            }
            return (data: data, image: image)
        }
        let request = (token: token, task: task)
        tasks[id] = request
        return request
    }

    private nonisolated static func decodeImage(
        _ data: Data,
        maximumPixelSize: Int
    ) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
