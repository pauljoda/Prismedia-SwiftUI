import SwiftUI

struct EntityDetailStringListEditor: View {
    let title: String
    let placeholder: String
    @Binding var values: [EntityDetailStringDraft]

    var body: some View {
        Section(title) {
            ForEach($values) { $item in
                HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                    TextField(placeholder, text: $item.value)

                    Button("Remove", systemImage: "minus.circle", role: .destructive) {
                        values.removeAll { $0.id == item.id }
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Remove \(title.lowercased()) value")
                }
            }

            Button("Add \(title)", systemImage: "plus") {
                values.append(EntityDetailStringDraft())
            }
        }
    }
}

#if DEBUG
    #Preview("Entity Detail String List Editor") {
        @Previewable @State var values = [
            EntityDetailStringDraft(value: "https://example.com")
        ]

        Form {
            EntityDetailStringListEditor(
                title: "Links",
                placeholder: "https://example.com",
                values: $values
            )
        }
        .preferredColorScheme(.dark)
    }
#endif
