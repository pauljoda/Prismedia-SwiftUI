#if os(tvOS)
import SwiftUI

struct TVEntityGridHeader<SortMenu: View, FilterButton: View, DisplayMenu: View>: View {
    let title: String
    @FocusState.Binding var focus: TVGridFocus?
    let onMove: (MoveCommandDirection) -> Void
    @ViewBuilder let sortMenu: () -> SortMenu
    @ViewBuilder let filterButton: () -> FilterButton
    @ViewBuilder let displayMenu: () -> DisplayMenu

    var body: some View {
        HStack(alignment: .center, spacing: PrismediaSpacing.extraExtraLarge) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(PrismediaColor.textPrimary)

            sortMenu()
                .buttonStyle(.glass)
                .focused($focus, equals: .sort)
            filterButton()
                .buttonStyle(.glass)
                .focused($focus, equals: .filter)
            displayMenu()
                .buttonStyle(.glass)
                .focused($focus, equals: .display)

            Spacer(minLength: 0)
        }
        .onMoveCommand(perform: onMove)
        .padding(.bottom, PrismediaSpacing.medium)
        .accessibilityIdentifier("entity.grid.header")
    }
}

#Preview("TV Entity Grid Header") {
    @Previewable @FocusState var focus: TVGridFocus?
    TVEntityGridHeader(
        title: "Movies",
        focus: $focus,
        onMove: { _ in },
        sortMenu: { Button("Sort") {} },
        filterButton: { Button("Filter") {} },
        displayMenu: { Button("Display") {} }
    )
    .padding(72)
}
#endif
