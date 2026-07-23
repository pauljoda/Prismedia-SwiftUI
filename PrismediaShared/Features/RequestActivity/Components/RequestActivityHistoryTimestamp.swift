import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityHistoryTimestamp: View {
        @Environment(\.locale) private var locale
        let date: Date
        let referenceDate: Date

        var body: some View {
            Text(date, format: relativeFormat)
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)
                .accessibilityLabel(Text(date, format: accessibilityFormat))
        }

        private var relativeFormat: Date.AnchoredRelativeFormatStyle {
            Date.AnchoredRelativeFormatStyle(
                anchor: referenceDate,
                presentation: .numeric,
                unitsStyle: .abbreviated,
                locale: locale
            )
        }

        private var accessibilityFormat: Date.FormatStyle {
            Date.FormatStyle(
                date: .complete,
                time: .complete,
                locale: locale,
                timeZone: .autoupdatingCurrent
            )
        }
    }

    #if DEBUG
        #Preview("Acquisition Review · History · Timestamp Component") {
            RequestActivityHistoryTimestamp(
                date: RequestActivityPreviewFixtures.referenceDate.addingTimeInterval(-3_660),
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
            .padding()
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
        }
    #endif
#endif
