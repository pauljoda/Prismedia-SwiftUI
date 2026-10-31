import SwiftUI

/// Two related views that both stay on screen across a wide display. With the
/// iOS 27.1 SDK the system arranges them (`ArrangementView`, split style): side
/// by side when the space is wider than tall and one above the other when it is
/// taller, each on its own side of iPhone Duo's fold. Older SDKs and other
/// platforms get two equal columns. Callers choose it on regular width only;
/// each pane fills the safe area it is given.
struct PrismediaArrangedPanes<Primary: View, Secondary: View>: View {
    @ViewBuilder var primary: Primary
    @ViewBuilder var secondary: Secondary

    var body: some View {
        #if os(iOS) && canImport(SwiftUICore, _version: 8.0.85)
            if #available(iOS 27.1, *) {
                ArrangementView {
                    primary
                } secondary: {
                    secondary
                }
            } else {
                columns
            }
        #else
            columns
        #endif
    }

    private var columns: some View {
        HStack(spacing: 0) {
            primary
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            secondary
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
