import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarMilestoneFilterMenu: View {
        @Binding var selection: EntityDateType?

        let options: [EntityDateType]

        var body: some View {
            Menu {
                Button {
                    selection = nil
                } label: {
                    if selection == nil {
                        Label("All milestones", systemImage: "checkmark")
                    } else {
                        Text("All milestones")
                    }
                }

                Divider()

                ForEach(options, id: \.self) { type in
                    Button {
                        selection = type
                    } label: {
                        if selection == type {
                            Label(type.displayName, systemImage: "checkmark")
                        } else {
                            Text(type.displayName)
                        }
                    }
                }
            } label: {
                Image(systemName: "calendar.badge.clock")
            }
            .accessibilityLabel("Milestone")
            .accessibilityValue(selection?.displayName ?? "All milestones")
            .help("Milestone")
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Calendar Milestone Filter") {
        @Previewable @State var selection: EntityDateType? = .digitalRelease

        ReleaseCalendarMilestoneFilterMenu(
            selection: $selection,
            options: [.theatricalRelease, .digitalRelease, .streamingRelease]
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
