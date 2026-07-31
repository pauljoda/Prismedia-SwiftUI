import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityAcquisitionStatusSummary: View {
        let status: AcquisitionStatus
        let message: String?
        let updatedAt: Date

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Label(
                    RequestActivityAcquisitionLifecyclePolicy.label(for: status),
                    systemImage: RequestActivityStatusPolicy.systemImage(for: status)
                )
                .font(.headline)
                .foregroundStyle(RequestActivityStatusPolicy.tone(for: status).foregroundStyle)

                if let description = RequestActivityAcquisitionLifecyclePolicy.description(
                    for: status,
                    message: message
                ) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                Text("Updated \(updatedAt, style: .relative)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .accessibilityElement(children: .combine)
        }
    }

    #if DEBUG
        #Preview("Acquisition Status · Downloading") {
            RequestActivityAcquisitionStatusSummary(
                status: .downloading,
                message: nil,
                updatedAt: RequestActivityPreviewFixtures.referenceDate
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }

        #Preview("Acquisition Status · Failed · Accessibility") {
            RequestActivityAcquisitionStatusSummary(
                status: .failed,
                message: "The download client rejected this release.",
                updatedAt: RequestActivityPreviewFixtures.referenceDate
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
            .dynamicTypeSize(.accessibility3)
        }
    #endif
#endif
