import SwiftUI

struct EntityDetailSectionSwitcher<MainContent: View>: View {
    let presentation: EntityDetailPresentation
    let selection: EntityDetailSectionID
    let horizontalPadding: CGFloat
    let support: EntityDetailSectionSupport
    @ViewBuilder let mainContent: () -> MainContent

    var body: some View {
        switch selection {
        case .details:
            mainContent()
        case .metadata, .markers, .transcript, .acquisition:
            #if os(tvOS)
                sectionPanel
            #else
                sectionPanel
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            #endif
        }
    }

    private var sectionPanel: some View {
        EntityDetailSectionPanel(
            presentation: presentation,
            section: selection,
            horizontalPadding: horizontalPadding,
            ownerLink: support.ownerLink,
            acquisitionService: support.acquisitionService,
            requestActivityService: support.requestActivityService,
            transcriptSourceLoader: support.transcriptSourceLoader,
            onAcquisitionMutated: support.onAcquisitionMutated,
            onEntityPruned: support.onEntityPruned
        )
    }
}

#if DEBUG
    #Preview("Entity Detail Section Switcher") {
        EntityDetailSectionSwitcher(
            presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
            selection: .metadata,
            horizontalPadding: PrismediaSpacing.extraLarge,
            support: EntityDetailSectionSupport()
        ) {
            Text("Main")
        }
    }
#endif
