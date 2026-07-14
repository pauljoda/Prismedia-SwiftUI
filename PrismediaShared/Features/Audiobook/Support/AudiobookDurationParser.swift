import Foundation

public enum AudiobookDurationParser {
    public static func seconds(from value: String?) -> Double? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let components = trimmed.split(separator: ":", omittingEmptySubsequences: false)
        guard components.count == 3,
            let minutes = Double(components[1]),
            let seconds = Double(components[2]),
            minutes.isFinite,
            seconds.isFinite,
            minutes >= 0,
            seconds >= 0
        else { return nil }

        let dayAndHour = components[0].split(separator: ".", maxSplits: 1).map(String.init)
        let days: Double
        let hours: Double
        if dayAndHour.count == 2 {
            guard let parsedDays = Double(dayAndHour[0]),
                let parsedHours = Double(dayAndHour[1]),
                parsedDays.isFinite,
                parsedHours.isFinite,
                parsedDays >= 0,
                parsedHours >= 0
            else { return nil }
            days = parsedDays
            hours = parsedHours
        } else {
            guard let parsedHours = Double(components[0]),
                parsedHours.isFinite,
                parsedHours >= 0
            else { return nil }
            days = 0
            hours = parsedHours
        }

        return (days * 86_400) + (hours * 3_600) + (minutes * 60) + seconds
    }
}
