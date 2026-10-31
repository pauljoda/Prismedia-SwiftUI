import SwiftUI

#if os(iOS) || os(macOS)
    /// One day of the compact month grid beside the day pane: its number, a ring
    /// when it is selected, and a dot for each of its first releases (orange for
    /// a search gate).
    struct ReleaseCalendarMonthDayCell: View {
        let date: Date
        let displayedMonth: Date
        let events: [ReleaseCalendarEvent]
        let isSelected: Bool
        /// The row height the grid gives each week; the day's circle shrinks with it.
        var height: CGFloat = 48
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: PrismediaSpacing.extraExtraSmall) {
                    Text(date, format: .dateTime.day())
                        .font(.callout.weight(isSelected || isToday ? .bold : .regular))
                        .monospacedDigit()
                        .foregroundStyle(numberStyle)
                        .frame(width: circleSize, height: circleSize)
                        .background {
                            if isSelected {
                                Circle().fill(PrismediaColor.accent)
                            }
                        }
                    HStack(spacing: 3) {
                        ForEach(events.prefix(ReleaseCalendarDatePolicy.visibleDayEventLimit)) { event in
                            Circle()
                                .fill(event.isSearchGate ? PrismediaColor.warning : PrismediaColor.textSecondary)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .opacity(isInDisplayedMonth ? 1 : 0.45)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }

        private var circleSize: CGFloat {
            min(34, height - 7 - PrismediaSpacing.extraExtraSmall)
        }

        private var numberStyle: Color {
            if isSelected { return PrismediaColor.onAccent }
            if isToday { return PrismediaColor.accent }
            return PrismediaColor.textPrimary
        }

        private var isToday: Bool {
            Calendar.current.isDateInToday(date)
        }

        private var isInDisplayedMonth: Bool {
            Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        }

        private var accessibilityLabel: String {
            let day = date.formatted(date: .complete, time: .omitted)
            switch events.count {
            case 0: return day
            case 1: return "\(day), 1 release"
            default: return "\(day), \(events.count) releases"
            }
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Selected Release Day") {
        HStack {
            ReleaseCalendarMonthDayCell(
                date: ReleaseCalendarPreviewFixtures.day,
                displayedMonth: ReleaseCalendarPreviewFixtures.day,
                events: ReleaseCalendarPreviewFixtures.events,
                isSelected: true,
                action: {}
            )
            ReleaseCalendarMonthDayCell(
                date: ReleaseCalendarPreviewFixtures.day,
                displayedMonth: ReleaseCalendarPreviewFixtures.day,
                events: ReleaseCalendarPreviewFixtures.events,
                isSelected: false,
                action: {}
            )
        }
        .frame(width: 120)
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
