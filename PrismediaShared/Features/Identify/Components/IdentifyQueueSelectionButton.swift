import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifyQueueSelectionButton: View {
        @Binding var isSelected: Bool
        let title: String

        var body: some View {
            Button {
                isSelected.toggle()
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(
                        isSelected
                            ? PrismediaColor.materialSpectrumViolet
                            : PrismediaColor.textSecondary
                    )
                    .frame(
                        minWidth: PrismediaLayout.minimumHitTarget,
                        minHeight: PrismediaLayout.minimumHitTarget
                    )
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select \(title)")
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
        }
    }

    #if DEBUG
        #Preview("Identify Selection") {
            @Previewable @State var isSelected = true

            IdentifyQueueSelectionButton(isSelected: $isSelected, title: "Arrival")
                .padding()
                .background(PrismediaColor.background)
        }
    #endif
#endif
