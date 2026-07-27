import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarMonthNavigationControls: View {
        let isDisabled: Bool
        let onPrevious: () -> Void
        let onNext: () -> Void

        var body: some View {
            PrismediaGlassButtonGroup {
                PrismediaButton(
                    "Previous month",
                    systemImage: "chevron.left",
                    form: .compactIcon,
                    action: onPrevious
                )
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("release-calendar.previous-month")

                Spacer()

                PrismediaButton(
                    "Next month",
                    systemImage: "chevron.right",
                    form: .compactIcon,
                    action: onNext
                )
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("release-calendar.next-month")
            }
            .disabled(isDisabled)
            .padding(PrismediaSpacing.large)
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Calendar Navigation") {
        ReleaseCalendarMonthNavigationControls(
            isDisabled: false,
            onPrevious: {},
            onNext: {}
        )
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
