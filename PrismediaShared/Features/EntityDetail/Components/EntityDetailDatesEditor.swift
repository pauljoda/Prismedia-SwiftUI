import SwiftUI

struct EntityDetailDatesEditor: View {
    @Binding var values: [EntityDetailKeyValueDraft]

    var body: some View {
        Section("Release Dates") {
            ForEach($values) { $item in
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    HStack {
                        Picker("Milestone", selection: $item.key) {
                            if EntityDateType(rawValue: item.key) == nil, !item.key.isEmpty {
                                Text(item.key.replacingOccurrences(of: "-", with: " ").capitalized)
                                    .tag(item.key)
                            }
                            ForEach(EntityDateType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type.rawValue)
                            }
                        }

                        Button("Remove date", systemImage: "minus.circle", role: .destructive) {
                            values.removeAll { $0.id == item.id }
                        }
                        .labelStyle(.iconOnly)
                    }
                    TextField("YYYY-MM-DD", text: $item.value)
                        #if os(iOS)
                            .textContentType(.dateTime)
                        #endif
                }
            }

            Button("Add release date", systemImage: "plus") {
                values.append(EntityDetailKeyValueDraft(key: EntityDateType.release.rawValue))
            }
        }
    }
}

#if DEBUG
    #Preview("Entity Release Dates Editor") {
        @Previewable @State var dates = [
            EntityDetailKeyValueDraft(key: "streaming-release", value: "2026-08-14")
        ]
        Form {
            EntityDetailDatesEditor(values: $dates)
        }
        .preferredColorScheme(.dark)
    }
#endif
