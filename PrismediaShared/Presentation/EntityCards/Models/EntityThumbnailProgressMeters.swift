import Foundation

/// The progress meters a thumbnail draws along its artwork's bottom edge: one for most entities, and
/// reading plus listening for an unfinished Book that keeps its formats Separate, so the two
/// progresses never read as one number.
public enum EntityThumbnailProgressMeters: Equatable, Sendable {
    /// Nothing started, or nothing to measure.
    case none
    /// One fraction (0...1) watched, read, or consumed.
    case single(Double)
    /// A Separate Book's reading and listening fractions (0...1), each from its own exact position.
    case separate(reading: Double, listening: Double)

    // MARK: - Variables

    /// Whether any meter is drawn.
    public var isVisible: Bool {
        self != .none
    }

    /// Spoken progress for a Separate Book, which a single meter never needed.
    var accessibilityDescription: String? {
        guard case .separate(let reading, let listening) = self else { return nil }
        return String(
            localized: "Read \(Self.wholePercent(reading)) percent, listened \(Self.wholePercent(listening)) percent"
        )
    }

    // MARK: - Initializers

    /// Resolves the meters from the server's thumbnail projection. Older servers never mark a Book
    /// Separate, so they keep the single meter.
    public init(item: EntityThumbnail) {
        let reading = Self.startedFraction(item.progress)
        guard item.progressSeparate else {
            self = reading.map(Self.single) ?? .none
            return
        }
        let listening = Self.startedFraction(item.listeningProgress)
        if reading == nil, listening == nil {
            self = .none
        } else {
            self = .separate(reading: reading ?? 0, listening: listening ?? 0)
        }
    }

    // MARK: - Actions - Fractions

    private static func startedFraction(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value > 0 else { return nil }
        return min(1, value)
    }

    private static func wholePercent(_ fraction: Double) -> Int {
        Int((fraction * 100).rounded())
    }
}
