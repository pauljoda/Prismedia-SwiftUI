#if os(tvOS)
    import SwiftUI

    struct EntityDetailPlatformSectionLayout<Actions: View, Picker: View, Panel: View>: View {
        let selectedSection: EntityDetailSectionID
        @ViewBuilder let actions: () -> Actions
        @ViewBuilder let picker: () -> Picker
        @ViewBuilder let panel: () -> Panel

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                picker()

                if selectedSection == .metadata {
                    actions()
                }

                panel()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    #Preview("TV Entity Detail · Metadata Controls") {
        EntityDetailPlatformSectionLayout(
            selectedSection: .metadata,
            actions: { Text("Library controls") },
            picker: { Text("Sections") },
            panel: { Text("Metadata") }
        )
        .padding(72)
    }
#endif
