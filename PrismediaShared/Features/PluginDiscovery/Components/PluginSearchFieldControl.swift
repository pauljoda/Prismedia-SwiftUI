import SwiftUI

#if os(iOS) || os(macOS)
    struct PluginSearchFieldControl: View {
        let field: AdministrativePluginSearchField
        @Binding var value: String
        let isDisabled: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                input

                if let help = field.help, !help.isEmpty {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .contain)
        }

        @ViewBuilder
        private var input: some View {
            #if os(iOS)
                baseInput
                    .keyboardType(keyboardType)
            #else
                baseInput
            #endif
        }

        private var baseInput: some View {
            TextField(field.label, text: $value, prompt: Text(field.placeholder ?? field.label))
                .disabled(isDisabled)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(accessibilityHint)
        }

        #if os(iOS)
            private var keyboardType: UIKeyboardType {
                switch field.type {
                case "number": .decimalPad
                case "year": .numberPad
                default: .default
                }
            }
        #endif

        private var accessibilityLabel: String {
            field.required ? "\(field.label), required" : field.label
        }

        private var accessibilityHint: String {
            if let help = field.help, !help.isEmpty { return help }
            return field.type == "year" ? "Enter a four-digit year." : ""
        }
    }

    #if DEBUG
        #Preview("Plugin Search Field") {
            @Previewable @State var value = "Arrival"
            PreviewShell {
                PluginSearchFieldControl(
                    field: PluginSearchPreviewFixtures.provider.supports[0].search!.fields[0],
                    value: $value,
                    isDisabled: false
                )
                .padding()
            }
        }
    #endif
#endif
