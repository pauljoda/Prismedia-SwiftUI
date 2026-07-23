import SwiftUI

struct EntityAcquisitionSummaryView: View {
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText

    let acquisition: EntityAcquisitionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text("Latest Acquisition")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LabeledContent("Status", value: acquisition.status.entityDetailDisplayName)

            if let progress = acquisition.progress {
                ProgressView(value: min(max(progress, 0), 1)) {
                    Text("Download progress")
                } currentValueLabel: {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                .accessibilityValue(
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                )
            }

            if let message = acquisition.statusMessage, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(artworkSecondaryText)
            }
        }
    }
}

#if DEBUG
    #Preview("Entity Acquisition Summary · Progress") {
        EntityAcquisitionSummaryView(
            acquisition: EntityAcquisitionPanelPreviewFixtures.downloadingState.latestAcquisition!
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Entity Acquisition Summary · Accessibility") {
        EntityAcquisitionSummaryView(
            acquisition: EntityAcquisitionPanelPreviewFixtures.downloadingState.latestAcquisition!
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .dynamicTypeSize(.accessibility3)
    }
#endif
