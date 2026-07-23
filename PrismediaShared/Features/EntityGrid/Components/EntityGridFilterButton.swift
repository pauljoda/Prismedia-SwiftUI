import SwiftUI

struct EntityGridFilterButton: View {
    let activeFilterCount: Int
    let onPresent: () -> Void

    var body: some View {
        Button(action: onPresent) {
            Image(
                systemName: activeFilterCount > 0
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
            .overlay(alignment: .topTrailing) {
                if activeFilterCount > 0 {
                    Text(String(activeFilterCount))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(PrismediaColor.onAccent)
                        .padding(PrismediaSpacing.extraSmall)
                        .background(PrismediaColor.accent, in: Circle())
                        .offset(
                            x: PrismediaSpacing.small - PrismediaLayout.hairline,
                            y: -(PrismediaSpacing.small - PrismediaLayout.hairline)
                        )
                }
            }
        }
        .accessibilityLabel("Filters")
        .accessibilityValue("\(activeFilterCount) active")
        .accessibilityIdentifier("entity.grid.filter")
    }
}

#if DEBUG
    #Preview("Entity Grid Filter · States") {
        PrismediaGlassButtonGroup(spacing: PrismediaSpacing.medium) {
            EntityGridFilterButton(activeFilterCount: 0, onPresent: {})
            EntityGridFilterButton(activeFilterCount: 3, onPresent: {})
        }
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
