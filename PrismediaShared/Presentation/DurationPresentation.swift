import Foundation

/// User-facing duration formatting for summary and progress surfaces.
public enum DurationPresentation {
    /// Formats accumulated activity with explicit units and rolls durations longer than one day
    /// into days instead of leaving an ambiguous, unbounded hour field.
    public static func activity(
        _ seconds: Double,
        locale: Locale = .current
    ) -> String {
        Duration.seconds(wholeSeconds(seconds)).formatted(
            Duration.UnitsFormatStyle(
                allowedUnits: [.days, .hours, .minutes, .seconds],
                width: .narrow,
                maximumUnitCount: 2
            )
            .locale(locale)
        )
    }

    /// Formats a true time-based media position with named units for non-player summaries.
    public static func progress(
        _ seconds: Double,
        locale: Locale = .current
    ) -> String {
        Duration.seconds(wholeSeconds(seconds)).formatted(
            Duration.UnitsFormatStyle(
                allowedUnits: [.hours, .minutes, .seconds],
                width: .abbreviated,
                maximumUnitCount: 2
            )
            .locale(locale)
        )
    }

    private static func wholeSeconds(_ seconds: Double) -> Double {
        guard seconds.isFinite, seconds >= 0 else { return 0 }
        return seconds.rounded(.down)
    }
}
