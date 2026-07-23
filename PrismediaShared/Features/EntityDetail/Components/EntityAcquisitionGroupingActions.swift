import SwiftUI

struct EntityAcquisitionGroupingActions: View {
    let monitoringScope: String?
    let canSearchMissingChildren: Bool
    let missingChildCount: Int
    let isChecking: Bool
    let isSearching: Bool
    let isDisabled: Bool
    let onCheck: () -> Void
    let onSearchMissing: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Divider()
            if let monitoringScope {
                LabeledContent("Monitoring Scope", value: monitoringScope)
                    .foregroundStyle(PrismediaColor.textPrimary)
            }

            PrismediaGlassButtonStack {
                PrismediaButton(
                    "Check for New Content Now",
                    systemImage: "arrow.clockwise",
                    form: .fill,
                    isLoading: isChecking,
                    loadingTitle: "Checking…",
                    action: onCheck
                )
                .frame(maxWidth: .infinity)

                if canSearchMissingChildren {
                    PrismediaButton(
                        missingChildCount > 0
                            ? "Search \(missingChildCount) Missing"
                            : "Search for Missing Content",
                        systemImage: "magnifyingglass",
                        form: .fill,
                        isLoading: isSearching,
                        loadingTitle: "Searching…",
                        action: onSearchMissing
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
            .disabled(isDisabled)
        }
    }
}

#if DEBUG
    #Preview("Acquisition Grouping · Content") {
        EntityAcquisitionGroupingActions(
            monitoringScope: "All current and future",
            canSearchMissingChildren: true,
            missingChildCount: 4,
            isChecking: false,
            isSearching: false,
            isDisabled: false,
            onCheck: {},
            onSearchMissing: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Acquisition Grouping · Busy · Accessibility") {
        EntityAcquisitionGroupingActions(
            monitoringScope: "Missing only",
            canSearchMissingChildren: true,
            missingChildCount: 0,
            isChecking: false,
            isSearching: true,
            isDisabled: true,
            onCheck: {},
            onSearchMissing: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .dynamicTypeSize(.accessibility3)
    }
#endif
