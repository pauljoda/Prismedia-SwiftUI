import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseCalendarMonthHeader: View {
        let month: Date
        let isDisabled: Bool
        let onPrevious: () -> Void
        let onNext: () -> Void

        var body: some View {
            ViewThatFits(in: .horizontal) {
                PrismediaGlassButtonGroup(spacing: PrismediaSpacing.large) {
                    previousButton
                    monthTitle
                        .fixedSize()
                        .frame(maxWidth: .infinity)
                    nextButton
                }

                VStack(spacing: PrismediaSpacing.small) {
                    monthTitle
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                    PrismediaGlassButtonGroup {
                        previousButton
                        Spacer()
                        nextButton
                    }
                }
            }
            .disabled(isDisabled)
            .padding(PrismediaSpacing.large)
        }

        private var monthTitle: some View {
            Text(month, format: .dateTime.month(.wide).year())
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("release-calendar.month")
        }

        private var previousButton: some View {
            PrismediaButton(
                "Previous month",
                systemImage: "chevron.left",
                form: .compactIcon,
                action: onPrevious
            )
            .frame(minWidth: PrismediaLayout.minimumHitTarget, minHeight: PrismediaLayout.minimumHitTarget)
            .accessibilityIdentifier("release-calendar.previous-month")
        }

        private var nextButton: some View {
            PrismediaButton(
                "Next month",
                systemImage: "chevron.right",
                form: .compactIcon,
                action: onNext
            )
            .frame(minWidth: PrismediaLayout.minimumHitTarget, minHeight: PrismediaLayout.minimumHitTarget)
            .accessibilityIdentifier("release-calendar.next-month")
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Calendar Navigation") {
        ReleaseCalendarMonthHeader(
            month: Date(timeIntervalSince1970: 1_788_912_000),
            isDisabled: false,
            onPrevious: {},
            onNext: {}
        )
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }

    #Preview("Release Calendar Navigation · Accessibility") {
        ReleaseCalendarMonthHeader(
            month: Date(timeIntervalSince1970: 1_788_912_000),
            isDisabled: false,
            onPrevious: {},
            onNext: {}
        )
        .frame(width: 320)
        .environment(\.dynamicTypeSize, .accessibility3)
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
