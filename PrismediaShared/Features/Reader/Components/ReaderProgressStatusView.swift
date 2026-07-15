import SwiftUI

struct ReaderProgressStatusView: View {
    let status: ReaderProgressStatus
    let accessibilityIdentifier: String

    var body: some View {
        VStack(spacing: PrismediaLayout.hairline) {
            Text(status.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Text(status.counterText)
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, PrismediaSpacing.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#if DEBUG
    #Preview("Reader Progress Status") {
        ReaderProgressStatusView(
            status: ReaderProgressStatus(
                title: "The First Signal",
                counterText: "10 / 51",
                accessibilityLabel: "The First Signal, page 10 of 51"
            ),
            accessibilityIdentifier: "preview-reader.progress"
        )
        .padding()
        .background(.black)
        .preferredColorScheme(.dark)
    }
#endif
