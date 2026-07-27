import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarMediaFilterMenu: View {
        @Binding var selection: EntityKind?

        let options: [EntityKind]

        var body: some View {
            Menu {
                Button {
                    selection = nil
                } label: {
                    if selection == nil {
                        Label("All media", systemImage: "checkmark")
                    } else {
                        Text("All media")
                    }
                }

                Divider()

                ForEach(options, id: \.self) { kind in
                    Button {
                        selection = kind
                    } label: {
                        if selection == kind {
                            Label(kind.displayLabel, systemImage: "checkmark")
                        } else {
                            Text(kind.displayLabel)
                        }
                    }
                }
            } label: {
                Image(
                    systemName: selection == nil
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill"
                )
            }
            .accessibilityLabel("Media kind")
            .accessibilityValue(selection?.displayLabel ?? "All media")
            .help("Media kind")
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Calendar Media Filter") {
        @Previewable @State var selection: EntityKind? = .movie

        ReleaseCalendarMediaFilterMenu(
            selection: $selection,
            options: [.movie, .videoSeries, .book]
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
