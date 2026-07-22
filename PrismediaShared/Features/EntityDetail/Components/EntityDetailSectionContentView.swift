import SwiftUI

struct EntityDetailSectionContentView<Actions: View>: View {
    let presentation: EntityDetailPresentation
    @Binding var selection: EntityDetailSectionID
    let horizontalPadding: CGFloat
    let support: EntityDetailSectionSupport
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        EntityDetailPlatformSectionLayout(
            selectedSection: selection,
            actions: actions,
            picker: {
                if !presentation.sections.isEmpty {
                    EntityDetailSectionPicker(
                        sections: presentation.sections,
                        selection: $selection,
                        horizontalPadding: horizontalPadding
                    )
                }
            },
            panel: {
                EntityDetailSectionSwitcher(
                    presentation: presentation,
                    selection: presentation.sections.isEmpty ? .details : selection,
                    horizontalPadding: horizontalPadding,
                    support: support
                ) {
                    sectionPanel(section: .details)
                }
            }
        )
    }

    private func sectionPanel(section: EntityDetailSectionID) -> some View {
        EntityDetailSectionPanel(
            presentation: presentation,
            section: section,
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
    #Preview("Entity Detail · Inline Sections") {
        @Previewable @State var selection = EntityDetailSectionID.details

        PreviewShell {
            ScrollView {
                EntityDetailSectionContentView(
                    presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
                    selection: $selection,
                    horizontalPadding: PrismediaSpacing.extraLarge,
                    support: EntityDetailSectionSupport(),
                    actions: { EmptyView() }
                )
            }
        }
    }
#endif
