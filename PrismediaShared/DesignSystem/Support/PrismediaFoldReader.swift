import SwiftUI

/// Reports where iPhone Duo's fold crosses this view while the device is half
/// closed. Folded like a book the fold runs down the view, dividing it into a
/// left and a right side; half closed on a table it runs across, leaving a
/// raised half for looking and a flat half for touching. Each reader reports
/// nil while the display is flat, folds the other way, or has no fold. The frame
/// is in the view's own space, measured from its leading edge, and already
/// includes the clearance the system keeps clear of controls. Reserved regions
/// exist only in the iOS 27.1 SDK; elsewhere it never reports one.
struct PrismediaFoldReader: ViewModifier {
    /// True for the tabletop fold, which runs across; false for the book fold.
    let runsAcross: Bool
    let action: (CGRect?) -> Void

    func body(content: Content) -> some View {
        #if os(iOS) && canImport(SwiftUICore, _version: 8.0.85)
            if #available(iOS 27.1, *) {
                content.onGeometryChange(for: CGRect?.self) { proxy in
                    proxy
                        .reservedRegions(kind: .division)
                        .first { region in
                            region.isActive
                                && (region.frame.width > region.frame.height) == runsAcross
                        }?
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
    /// The fold while the device sits half closed on a table, running across this view.
    func onTabletopFoldChange(_ action: @escaping (CGRect?) -> Void) -> some View {
        modifier(PrismediaFoldReader(runsAcross: true, action: action))
    }

    /// The fold while the device is folded like a book, running down this view.
    func onBookFoldChange(_ action: @escaping (CGRect?) -> Void) -> some View {
        modifier(PrismediaFoldReader(runsAcross: false, action: action))
    }
}
