#if os(macOS)
    import SwiftUI

    struct EntityDetailPlatformSectionLayout<Actions: View, Picker: View, Panel: View>: View {
        let selectedSection: EntityDetailSectionID
        @ViewBuilder let actions: () -> Actions
        @ViewBuilder let picker: () -> Picker
        @ViewBuilder let panel: () -> Panel

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                actions()
                picker()
                panel()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    #Preview("Mac Entity Detail Sections") {
        EntityDetailPlatformSectionLayout(
            selectedSection: .details,
            actions: { Text("Actions") },
            picker: { Text("Sections") },
            panel: { Text("Details") }
        )
        .padding()
    }
#endif
