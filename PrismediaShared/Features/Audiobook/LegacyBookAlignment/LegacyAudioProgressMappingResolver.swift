import Foundation

/// Converts a player position into an older server's Book cursor through a client-built
/// `PlaybackProgressMapping`. Servers from 3.8 receive listening checkpoints instead.
struct LegacyAudioProgressMappingResolver: Sendable {
    func progressRequest(
        mapping: PlaybackProgressMapping,
        offsetSeconds: Double,
        durationSeconds: Double,
        activitySeconds: Double?,
        completed: Bool,
        includesBookListeningPosition: Bool = false
    ) -> EntityProgressUpdateRequest {
        let duration = durationSeconds.isFinite ? max(0, durationSeconds) : 0
        let offset = offsetSeconds.isFinite ? max(0, offsetSeconds) : 0
        let sourceStart = mapping.sourceStartSeconds ?? 0
        let sourceEnd = mapping.sourceEndSeconds ?? duration
        let sourceSpan = max(0, sourceEnd - sourceStart)
        let fraction = sourceSpan > 0 ? bounded((offset - sourceStart) / sourceSpan) : 0
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
            activityKind: .listening,
            listening: includesBookListeningPosition
                ? BookListeningPositionRequest(
                    trackEntityID: mapping.itemID,
                    markerID: mapping.audioMarkerID,
                    offsetSeconds: offset
                )
                : nil
        )
    }

    private func bounded(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(0, value), 1)
    }
}
