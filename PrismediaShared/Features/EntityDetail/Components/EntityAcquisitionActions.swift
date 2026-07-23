import SwiftUI

struct EntityAcquisitionActions: View {
    let showsSearchForRelease: Bool
    let showsSearchAgain: Bool
    let isSearchingForRelease: Bool
    let isSearchingAgain: Bool
    let primaryTint: Color
    let isDisabled: Bool
    let onSearchForRelease: () -> Void
    let onSearchAgain: () -> Void

    var body: some View {
        PrismediaGlassButtonStack {
            if showsSearchForRelease {
                PrismediaButton(
                    "Search for release",
                    systemImage: "magnifyingglass",
                    variant: .prominent,
                    form: .fill,
                    primaryTint: primaryTint,
                    isLoading: isSearchingForRelease,
                    loadingTitle: "Searching…",
                    action: onSearchForRelease
                )
            }

            if showsSearchAgain {
                PrismediaButton(
                    "Search Again",
                    systemImage: "arrow.clockwise",
                    form: .fill,
                    isLoading: isSearchingAgain,
                    loadingTitle: "Searching…",
                    action: onSearchAgain
                )
            }
        }
        .frame(maxWidth: .infinity)
        .prismediaCompactActionControlSize()
        .disabled(isDisabled)
    }
}

#if DEBUG
    #Preview("Entity Acquisition Actions · Request") {
        EntityAcquisitionActions(
            showsSearchForRelease: true,
            showsSearchAgain: false,
            isSearchingForRelease: false,
            isSearchingAgain: false,
            primaryTint: PrismediaColor.spectrumCyan,
            isDisabled: false,
            onSearchForRelease: {},
            onSearchAgain: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Entity Acquisition Actions · Busy") {
        EntityAcquisitionActions(
            showsSearchForRelease: false,
            showsSearchAgain: true,
            isSearchingForRelease: false,
            isSearchingAgain: true,
            primaryTint: PrismediaColor.spectrumCyan,
            isDisabled: true,
            onSearchForRelease: {},
            onSearchAgain: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
