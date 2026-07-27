import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarDaySheet: View {
        @Environment(\.dismiss) private var dismiss
        let selection: ReleaseCalendarDaySelection
        let resolveAssetURL: (String?) -> URL?
        let onOpen: (ReleaseCalendarEvent) -> Void

        var body: some View {
            NavigationStack {
                List(selection.events) { event in
                    ReleaseCalendarEventRow(
                        event: event,
                        resolveAssetURL: resolveAssetURL,
                        onOpen: {
                            dismiss()
                            onOpen(event)
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .prismediaScreenBackground()
                .navigationTitle(selection.date.formatted(date: .complete, time: .omitted))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", action: dismiss.callAsFunction)
                    }
                }
            }
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Day List") {
        PreviewShell {
            ReleaseCalendarDaySheet(
                selection: ReleaseCalendarDaySelection(
                    date: ReleaseCalendarPreviewFixtures.day,
                    events: ReleaseCalendarPreviewFixtures.events
                ),
                resolveAssetURL: { _ in nil },
                onOpen: { _ in }
            )
        }
        .preferredColorScheme(.dark)
    }
#endif
