import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarDayCell: View {
        let date: Date
        let displayedMonth: Date
        let events: [ReleaseCalendarEvent]
        let onOpen: (ReleaseCalendarEvent) -> Void
        let onShowAll: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(date, format: .dateTime.day())
                    .font(.caption.bold())
                    .foregroundStyle(isInDisplayedMonth ? PrismediaColor.textPrimary : PrismediaColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                ForEach(events.prefix(ReleaseCalendarDatePolicy.visibleDayEventLimit)) { event in
                    Button {
                        onOpen(event)
                    } label: {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(event.isSearchGate ? PrismediaColor.warning : PrismediaColor.accent)
                                .frame(width: 5, height: 5)
                            Text(ReleaseCalendarPresentationPolicy.title(for: event))
                                .lineLimit(1)
                        }
                        .font(.caption2)
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }

                if events.count > ReleaseCalendarDatePolicy.visibleDayEventLimit {
                    Button("+\(events.count - ReleaseCalendarDatePolicy.visibleDayEventLimit) more", action: onShowAll)
                        .font(.caption2.bold())
                        .foregroundStyle(PrismediaColor.accent)
                        .accessibilityLabel("Show all \(events.count) releases on \(date.formatted(date: .complete, time: .omitted))")
                }
                Spacer(minLength: 0)
            }
            .padding(PrismediaSpacing.small)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(PrismediaColor.groupedContentBackground, in: .rect(cornerRadius: PrismediaRadius.compact))
            .opacity(isInDisplayedMonth ? 1 : 0.55)
            .accessibilityElement(children: .contain)
        }

        private var isInDisplayedMonth: Bool {
            Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Crowded Release Day") {
        NavigationStack {
            ReleaseCalendarDayCell(
                date: ReleaseCalendarPreviewFixtures.day,
                displayedMonth: ReleaseCalendarPreviewFixtures.day,
                events: ReleaseCalendarPreviewFixtures.events,
                onOpen: { _ in },
                onShowAll: {}
            )
            .frame(width: 180)
            .padding()
        }
        .preferredColorScheme(.dark)
    }
#endif
