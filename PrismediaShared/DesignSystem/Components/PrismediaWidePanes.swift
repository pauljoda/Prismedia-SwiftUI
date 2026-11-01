import SwiftUI

/// Two panes where the space is wider than it is tall and at least
/// ``PrismediaLayout/paneSplitMinimumWidth`` wide, and one combined view
/// elsewhere. Use it for pages whose panes each scroll: stacked one above the
/// other in a narrow column (one side of a folded iPhone Duo beside the
/// sidebar, or the open display in portrait) each would get half a screen, and
/// side by side beside the sidebar each would be barely wider than a phone, so
/// the page keeps its single column there. Callers choose it on regular width
/// only.
struct PrismediaWidePanes<Primary: View, Secondary: View, Combined: View>: View {
    /// The narrowest space that still splits.
    var minimumWidth = PrismediaLayout.paneSplitMinimumWidth
    @ViewBuilder var primary: Primary
    @ViewBuilder var secondary: Secondary
    @ViewBuilder var combined: Combined

    @State private var isWide = false

    var body: some View {
        Group {
            if isWide {
                PrismediaArrangedPanes {
                    primary
                } secondary: {
                    secondary
                }
            } else {
                combined
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width > proxy.size.height && proxy.size.width >= minimumWidth
        } action: {
            isWide = $0
        }
    }
}
