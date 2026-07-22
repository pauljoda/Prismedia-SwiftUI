import SwiftUI

struct EntityDetailSectionContentView<Actions: View>: View {
    let presentation: EntityDetailPresentation
    @Binding var selection: EntityDetailSectionID
    let horizontalPadding: CGFloat
    let ownerLink: EntityLink?
    let acquisitionService: (any EntityAcquisitionServicing)?
    let requestActivityService: (any RequestActivityServicing)?
    let transcriptSourceLoader: (any EntityTranscriptSourceLoading)?
    let onAcquisitionMutated: @MainActor () async -> Void
    let onEntityPruned: @MainActor () -> Void
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
                sectionPanel(
                    section: presentation.sections.isEmpty ? .details : selection
                )
            }
        )
    }

    private func sectionPanel(section: EntityDetailSectionID) -> some View {
        EntityDetailSectionPanel(
            presentation: presentation,
            section: section,
            horizontalPadding: horizontalPadding,
            ownerLink: ownerLink,
            acquisitionService: acquisitionService,
            requestActivityService: requestActivityService,
            transcriptSourceLoader: transcriptSourceLoader,
            onAcquisitionMutated: onAcquisitionMutated,
            onEntityPruned: onEntityPruned
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
                    ownerLink: nil,
                    acquisitionService: nil,
                    requestActivityService: nil,
                    transcriptSourceLoader: nil,
                    onAcquisitionMutated: {},
                    onEntityPruned: {},
                    actions: { EmptyView() }
                )
            }
        }
    }
#endif
