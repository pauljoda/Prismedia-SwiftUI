import SwiftUI

struct EntityDetailSectionContentView: View {
    let presentation: EntityDetailPresentation
    @Binding var selection: EntityDetailSectionID
    let horizontalPadding: CGFloat
    let ownerLink: EntityLink?
    let acquisitionService: (any EntityAcquisitionServicing)?
    let requestActivityService: (any RequestActivityServicing)?
    let transcriptSourceLoader: (any EntityTranscriptSourceLoading)?
    let onAcquisitionMutated: @MainActor () async -> Void
    let onEntityPruned: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            if presentation.sections.isEmpty {
                sectionPanel(section: .details)
            } else {
                EntityDetailSectionPicker(
                    sections: presentation.sections,
                    selection: $selection,
                    horizontalPadding: horizontalPadding
                )

                sectionPanel(section: selection)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    onEntityPruned: {}
                )
            }
        }
    }
#endif
