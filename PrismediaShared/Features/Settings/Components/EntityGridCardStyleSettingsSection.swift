import SwiftUI

struct EntityGridCardStyleSettingsSection: View {
    @Binding var cardStyle: EntityGridCardStyle

    var body: some View {
        Section {
            Picker("Card Presentation", selection: $cardStyle) {
                ForEach(EntityGridCardStyle.allCases) { option in
                    Label(option.label, systemImage: option.systemImage)
                        .tag(option)
                }
            }
        } header: {
            Label("Entity Grids", systemImage: "rectangle.grid.2x2")
        } footer: {
            Text(
                "Artwork Fade extends each thumbnail behind its details. Text Below Artwork uses a simpler Apple-style layout. None shows only the artwork."
            )
        }
    }
}

#if DEBUG
    #Preview("Entity Grid Card Style Settings") {
        @Previewable @State var cardStyle = EntityGridCardStyle.detailsBelow

        Form {
            EntityGridCardStyleSettingsSection(cardStyle: $cardStyle)
        }
        .preferredColorScheme(.dark)
    }
#endif
