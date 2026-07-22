#if os(iOS)
    import SwiftUI

    struct EntityDetailPlatformContentLayout<BrowseContent: View, SecondaryContent: View>: View {
        let selectedSection: EntityDetailSectionID
        @ViewBuilder let browseContent: () -> BrowseContent
        @ViewBuilder let secondaryContent: () -> SecondaryContent

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                secondaryContent()

                if selectedSection == .details {
                    browseContent()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    #Preview("iOS Entity Detail Content Order") {
        EntityDetailPlatformContentLayout(
            selectedSection: .details,
            browseContent: { Text("Browse") },
            secondaryContent: { Text("Progress and metadata") }
        )
        .padding()
    }
#endif
