import SwiftUI

/// Reports where iPhone Duo's fold crosses this view while the device sits half
/// closed on a table: the fold then runs across the view, leaving a raised half
/// for looking and a flat half for touching. It reports nil while the display is
/// flat, folds like a book, or has no fold. The frame is in the view's own space
/// and already includes the clearance the system keeps clear of controls.
/// Reserved regions exist only in the iOS 27.1 SDK; elsewhere it never reports one.
struct PrismediaTabletopFoldReader: ViewModifier {
    let action: (CGRect?) -> Void

    func body(content: Content) -> some View {
        #if os(iOS) && canImport(SwiftUICore, _version: 8.0.85)
            if #available(iOS 27.1, *) {
                content.onGeometryChange(for: CGRect?.self) { proxy in
                    proxy
                        .reservedRegions(kind: .division, layoutDirectionBehavior: .fixed)
                        .first { $0.isActive && $0.frame.width > $0.frame.height }?
                        .frame
                } action: { frame in
                    action(frame)
                }
            } else {
                content
            }
        #else
            content
        #endif
    }
}

extension View {
    func onTabletopFoldChange(_ action: @escaping (CGRect?) -> Void) -> some View {
        modifier(PrismediaTabletopFoldReader(action: action))
    }
}
