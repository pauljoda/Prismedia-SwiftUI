import SwiftUI

#if os(iOS) || os(macOS)
    /// A native selection menu for controls embedded outside a Form. Its selected
    /// value wraps below the label instead of competing with it for row width.
    struct PrismediaMenuPicker<Selection: Hashable, Options: View>: View {
        let title: LocalizedStringKey
        let systemImage: String
        let selectedValue: String
        @Binding var selection: Selection
        @ViewBuilder let options: Options

        var body: some View {
            Menu {
                Picker(title, selection: $selection) {
                    options
                }
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Label(title, systemImage: systemImage)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                        Text(selectedValue)
                            .foregroundStyle(PrismediaColor.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(selectedValue)
        }
    }

    #if DEBUG
        #Preview("Menu Picker · Long Value") {
            @Previewable @State var value = "long"
            PrismediaMenuPicker(
                title: "Quality Profile",
                systemImage: "slider.horizontal.3",
                selectedValue: "A deliberately long profile name for future releases",
                selection: $value
            ) {
                Text("A deliberately long profile name for future releases").tag("long")
                Text("Standard").tag("standard")
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
