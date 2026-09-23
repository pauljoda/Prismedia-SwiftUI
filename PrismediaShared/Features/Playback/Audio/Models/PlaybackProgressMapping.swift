import Foundation

/// Converts one concrete player item into its owning Entity's canonical progress cursor.
public struct PlaybackProgressMapping: Codable, Equatable, Sendable {
    public let itemID: UUID
    public let currentEntityID: UUID
    public let unit: ProgressUnit
    public let startIndex: Int
    public let endIndex: Int
    public let total: Int
    public let mode: ReaderMode?
    /// Optional portable resource advanced as playback moves through the item.
    public let resourceLocation: String?
    /// Inclusive chapter window in the physical audio file, when it has embedded markers.
    public let sourceStartSeconds: Double?
    public let sourceEndSeconds: Double?
    public let audioMarkerID: UUID?

    private enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case legacyTrackID = "trackId"
        case currentEntityID = "currentEntityId"
        case unit, startIndex, endIndex, total, mode, resourceLocation
        case sourceStartSeconds, sourceEndSeconds
        case audioMarkerID = "audioMarkerId"
        case legacyReaderLocation = "readerLocation"
    }

    public init(
        itemID: UUID,
        currentEntityID: UUID,
        unit: ProgressUnit,
        startIndex: Int,
        endIndex: Int,
        total: Int,
        mode: ReaderMode?,
        resourceLocation: String? = nil,
        sourceStartSeconds: Double? = nil,
        sourceEndSeconds: Double? = nil,
        audioMarkerID: UUID? = nil
    ) {
        self.itemID = itemID
        self.currentEntityID = currentEntityID
        self.unit = unit
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.total = total
        self.mode = mode
        self.resourceLocation = resourceLocation
        self.sourceStartSeconds = sourceStartSeconds
        self.sourceEndSeconds = sourceEndSeconds
        self.audioMarkerID = audioMarkerID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemID = try container.decodeIfPresent(UUID.self, forKey: .itemID)
            ?? container.decode(UUID.self, forKey: .legacyTrackID)
        currentEntityID = try container.decode(UUID.self, forKey: .currentEntityID)
        unit = try container.decode(ProgressUnit.self, forKey: .unit)
        startIndex = try container.decode(Int.self, forKey: .startIndex)
        endIndex = try container.decode(Int.self, forKey: .endIndex)
        total = try container.decode(Int.self, forKey: .total)
        mode = try container.decodeIfPresent(ReaderMode.self, forKey: .mode)
        resourceLocation = try container.decodeIfPresent(String.self, forKey: .resourceLocation)
            ?? container.decodeIfPresent(String.self, forKey: .legacyReaderLocation)
        sourceStartSeconds = try container.decodeIfPresent(Double.self, forKey: .sourceStartSeconds)
        sourceEndSeconds = try container.decodeIfPresent(Double.self, forKey: .sourceEndSeconds)
        audioMarkerID = try container.decodeIfPresent(UUID.self, forKey: .audioMarkerID)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(itemID, forKey: .itemID)
        try container.encode(currentEntityID, forKey: .currentEntityID)
        try container.encode(unit, forKey: .unit)
        try container.encode(startIndex, forKey: .startIndex)
        try container.encode(endIndex, forKey: .endIndex)
        try container.encode(total, forKey: .total)
        try container.encodeIfPresent(mode, forKey: .mode)
        try container.encodeIfPresent(resourceLocation, forKey: .resourceLocation)
        try container.encodeIfPresent(sourceStartSeconds, forKey: .sourceStartSeconds)
        try container.encodeIfPresent(sourceEndSeconds, forKey: .sourceEndSeconds)
        try container.encodeIfPresent(audioMarkerID, forKey: .audioMarkerID)
    }

    public func containsSourceOffset(_ offset: Double, duration: Double) -> Bool {
        let start = sourceStartSeconds ?? 0
        let end = sourceEndSeconds ?? duration
        return offset >= start && (offset < end || (offset >= duration && end >= duration))
    }

    public func sourceOffset(for fraction: Double, duration: Double) -> Double {
        let start = sourceStartSeconds ?? 0
        let end = sourceEndSeconds ?? duration
        return start + min(max(0, fraction), 1) * max(0, end - start)
    }
}
