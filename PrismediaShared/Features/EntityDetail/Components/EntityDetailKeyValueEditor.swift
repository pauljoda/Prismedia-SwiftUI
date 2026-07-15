import SwiftUI

struct EntityDetailKeyValueEditor: View {
    let title: String
    let keyPlaceholder: String
    let valuePlaceholder: String
    let valueUsesNumberKeyboard: Bool
    @Binding var values: [EntityDetailKeyValueDraft]

    var body: some View {
        Section(title) {
            ForEach($values) { $item in
                HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.small) {
                    TextField(keyPlaceholder, text: $item.key)

                    TextField(valuePlaceholder, text: $item.value)
                        #if os(iOS)
                            .keyboardType(valueUsesNumberKeyboard ? .numberPad : .default)
                        #endif

                    Button("Remove", systemImage: "minus.circle", role: .destructive) {
                        values.removeAll { $0.id == item.id }
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Remove \(title.lowercased()) value")
                }
            }

            Button("Add \(title)", systemImage: "plus") {
                values.append(EntityDetailKeyValueDraft())
            }
        }
    }
}

#if DEBUG
    #Preview("Entity Detail Key Value Editor") {
        @Previewable @State var values = [
            EntityDetailKeyValueDraft(key: "tmdb", value: "603")
        ]

        Form {
            EntityDetailKeyValueEditor(
                title: "External IDs",
                keyPlaceholder: "Provider",
                valuePlaceholder: "ID",
                valueUsesNumberKeyboard: false,
                values: $values
            )
        }
        .preferredColorScheme(.dark)
    }
#endif
