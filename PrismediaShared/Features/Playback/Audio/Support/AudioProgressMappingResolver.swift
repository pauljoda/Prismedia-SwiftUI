import Foundation

struct AudioProgressMappingResolver: Sendable {
    func progressRequest(
        mapping: PlaybackProgressMapping,
        offsetSeconds: Double,
        durationSeconds: Double,
        activitySeconds: Double?,
        completed: Bool
    ) -> EntityProgressUpdateRequest {
        let duration = durationSeconds.isFinite ? max(0, durationSeconds) : 0
        let offset = offsetSeconds.isFinite ? max(0, offsetSeconds) : 0
        let fraction = duration > 0 ? bounded(offset / duration) : 0
        let index: Int
        if mapping.unit == .page {
            index = max(
                mapping.startIndex,
                min(mapping.endIndex, Int(ceil(fraction * Double(mapping.total))) - 1)
            )
        } else {
            index = max(
                mapping.startIndex,
                min(
                    mapping.endIndex,
                    Int(
                        (Double(mapping.startIndex)
                            + fraction * Double(mapping.endIndex - mapping.startIndex))
                            .rounded()
                    )
                )
            )
        }

        return EntityProgressUpdateRequest(
            currentEntityID: mapping.currentEntityID,
            unit: mapping.unit,
            index: index,
            total: mapping.total,
            mode: mapping.mode,
            completed: completed ? true : nil,
            location: mapping.resourceLocation.map {
                DocumentReaderProgressMapper.epubLocation(
                    chapterLocation: $0,
                    progress: fraction
                )
            },
            activitySeconds: activitySeconds,
            activityKind: .listening
        )
    }

    private func bounded(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(0, value), 1)
    }
}
