import SwiftUI

#if os(iOS) && canImport(SwiftUICore, _version: 8.0.85)
    @available(iOS 27.1, *)
    private struct PrismediaToolbarVerticalEdgeReader: View {
        let onChange: (Bool) -> Void
        @Environment(\.toolbarVerticalEdge) private var verticalEdge

        var body: some View {
            Color.clear
                .accessibilityHidden(true)
                .onChange(of: verticalEdge, initial: true) { _, edge in
                    onChange(edge != nil)
                }
        }
    }
#endif

/// Reports whether the system prefers a vertical bar here. Built with the iOS
/// 27.1 SDK, iPhone Duo lays navigation, toolbar and tab bar items down the side
/// of the display; `toolbarVerticalEdge` names that edge whether or not a bar is
/// visible, so this answers where controls belong rather than what is on screen.
/// Place it inside the navigation stack whose bars it describes; a sheet has
/// bars of its own. Older SDKs and other platforms never report one.
struct PrismediaVerticalBarReader: View {
    let onChange: (Bool) -> Void

    var body: some View {
        #if os(iOS) && canImport(SwiftUICore, _version: 8.0.85)
            if #available(iOS 27.1, *) {
                PrismediaToolbarVerticalEdgeReader(onChange: onChange)
            }
        #endif
    }
}
