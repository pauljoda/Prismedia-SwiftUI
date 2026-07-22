#if os(tvOS)
    import SwiftUI

    struct EntityDetailPlatformContentLayout<BrowseContent: View, SecondaryContent: View>: View {
        let selectedSection: EntityDetailSectionID
        @ViewBuilder let browseContent: () -> BrowseContent
        @ViewBuilder let secondaryContent: () -> SecondaryContent

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                if selectedSection == .details {
                    browseContent()
                }

                secondaryContent()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    #Preview("TV Entity Detail · Browse First") {
        EntityDetailPlatformContentLayout(
            selectedSection: .details,
            browseContent: { Text("Browse first").font(.largeTitle) },
            secondaryContent: { Text("Progress and metadata") }
        )
        .padding(72)
    }
#endif
