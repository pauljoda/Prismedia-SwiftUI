import Foundation

/// Body of `PATCH /api/entities/{id}/progress`.
///
/// A cursor report names the position itself: reading, and every kind with one shared cursor.
/// A listening report (servers from 3.8) names only the exact track position; the server records
/// the listening checkpoint and places the shared cursor from its own alignment.
public struct EntityProgressUpdateRequest: Encodable, Hashable, Sendable {
    // MARK: - Variables

    /// Exact audiobook position, for listening reports (and, on older servers, alongside a cursor).
    public let listening: BookListeningPositionRequest?
    public let currentEntityID: UUID?
    public let unit: ProgressUnit?
    public let index: Int?
    public let total: Int?
    public let mode: ReaderMode?
    public let completed: Bool?
    public let reset: Bool
    public let location: String?
    public let activitySeconds: Double?
    public let activityKind: ConsumptionActivityKind?
    public let utcOffsetMinutes: Int
    /// Modality whose checkpoint the report records, for kinds that keep modality checkpoints.
    public let modality: ConsumptionModality?

    // MARK: - Initializers

    /// A cursor report.
    public init(
        currentEntityID: UUID,
        unit: ProgressUnit,
        index: Int,
        total: Int,
        mode: ReaderMode?,
        completed: Bool?,
        reset: Bool = false,
        location: String? = nil,
        activitySeconds: Double? = nil,
        activityKind: ConsumptionActivityKind? = nil,
        utcOffsetMinutes: Int = TimeZone.current.secondsFromGMT() / 60,
        modality: ConsumptionModality? = nil,
        listening: BookListeningPositionRequest? = nil
    ) {
        self.init(
            listening: listening,
            currentEntityID: currentEntityID,
            unit: unit,
            index: index,
            total: total,
            mode: mode,
            completed: completed,
            reset: reset,
            location: location,
            activitySeconds: activitySeconds,
            activityKind: activityKind,
            utcOffsetMinutes: utcOffsetMinutes,
            modality: modality
        )
    }

    private init(
        listening: BookListeningPositionRequest?,
        currentEntityID: UUID?,
        unit: ProgressUnit?,
        index: Int?,
        total: Int?,
        mode: ReaderMode?,
        completed: Bool?,
        reset: Bool,
        location: String?,
        activitySeconds: Double?,
        activityKind: ConsumptionActivityKind?,
        utcOffsetMinutes: Int,
        modality: ConsumptionModality?
    ) {
        self.listening = listening
        self.currentEntityID = currentEntityID
        self.unit = unit
        self.index = index
        self.total = total
        self.mode = mode
        self.completed = completed
        self.reset = reset
        self.location = location
        self.activitySeconds = activitySeconds.flatMap {
            $0.isFinite && $0 > 0 ? min($0, 60) : nil
        }
        self.activityKind = activityKind
        self.utcOffsetMinutes = utcOffsetMinutes
        self.modality = modality
    }

    // MARK: - Actions - Listening Reports

    /// A listening report for servers that keep modality checkpoints (3.8+). It is sent on every
    /// player heartbeat, whether or not the chapter is paired with a readable chapter.
    public static func listening(
        _ position: BookListeningPositionRequest,
        completed: Bool?,
        reset: Bool = false,
        activitySeconds: Double? = nil,
        utcOffsetMinutes: Int = TimeZone.current.secondsFromGMT() / 60
    ) -> Self {
        Self(
            listening: position,
            currentEntityID: nil,
            unit: nil,
            index: nil,
            total: nil,
            mode: nil,
            completed: completed,
            reset: reset,
            location: nil,
            activitySeconds: activitySeconds,
            activityKind: nil,
            utcOffsetMinutes: utcOffsetMinutes,
            modality: .listening
        )
    }

    // MARK: - Actions - Activity

    func recordingActivity(
        seconds: Double?,
        kind: ConsumptionActivityKind
    ) -> Self {
        Self(
            listening: listening,
            currentEntityID: currentEntityID,
            unit: unit,
            index: index,
            total: total,
            mode: mode,
            completed: completed,
            reset: reset,
            location: location,
            activitySeconds: seconds,
            activityKind: kind,
            utcOffsetMinutes: utcOffsetMinutes,
            modality: modality
        )
    }
}

extension EntityProgressUpdateRequest {
    private enum CodingKeys: String, CodingKey {
        case currentEntityID = "currentEntityId"
        case unit, index, total, mode, completed, reset, location, activitySeconds, activityKind, utcOffsetMinutes
        case modality, listening
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let currentEntityID {
            // Cursor reports send explicit nulls so the server clears a stale mode or locator.
            try container.encode(currentEntityID, forKey: .currentEntityID)
            try container.encodeIfPresent(unit, forKey: .unit)
            try container.encodeIfPresent(index, forKey: .index)
            try container.encodeIfPresent(total, forKey: .total)
            try container.encodeIfPresent(mode, forKey: .mode)
            if mode == nil { try container.encodeNil(forKey: .mode) }
            try container.encodeIfPresent(location, forKey: .location)
            if location == nil { try container.encodeNil(forKey: .location) }
        }
        try container.encodeIfPresent(completed, forKey: .completed)
        if completed == nil { try container.encodeNil(forKey: .completed) }
        try container.encode(reset, forKey: .reset)
        try container.encodeIfPresent(activitySeconds, forKey: .activitySeconds)
        try container.encodeIfPresent(activityKind, forKey: .activityKind)
        try container.encode(utcOffsetMinutes, forKey: .utcOffsetMinutes)
        try container.encodeIfPresent(modality, forKey: .modality)
        try container.encodeIfPresent(listening, forKey: .listening)
    }
}
