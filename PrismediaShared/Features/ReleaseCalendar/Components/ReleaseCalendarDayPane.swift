import SwiftUI

#if os(iOS) || os(macOS)
    /// The releases on the day selected in the month grid, listed beside it on
    /// regular width.
    struct ReleaseCalendarDayPane: View {
        let date: Date
        let events: [ReleaseCalendarEvent]
        let resolveAssetURL: (String?) -> URL?
        let onOpen: (ReleaseCalendarEvent) -> Void

        var body: some View {
            List {
                Section {
                    if events.isEmpty {
                        ContentUnavailableView("No Releases", systemImage: "calendar")
                            .accessibilityIdentifier("release-calendar.day.empty")
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(events) { event in
                            ReleaseCalendarEventRow(
                                event: event,
                                resolveAssetURL: resolveAssetURL,
                                onOpen: { onOpen(event) }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                } header: {
                    Text(date.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("release-calendar.day.title")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Day Pane") {
        PreviewShell {
            ReleaseCalendarDayPane(
                date: ReleaseCalendarPreviewFixtures.day,
                events: ReleaseCalendarPreviewFixtures.events,
                resolveAssetURL: { _ in nil },
                onOpen: { _ in }
            )
            .prismediaScreenBackground()
        }
        .preferredColorScheme(.dark)
    }
#endif
