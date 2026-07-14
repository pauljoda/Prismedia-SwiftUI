import Foundation

/// SwiftUI owns the full-screen boundary. The embedded AVPlayerViewController
/// converts its native Menu dismissal request into cover state instead of
/// attempting a second UIKit presentation transition through UIHostingController.
enum TVFullscreenPresentationPolicy {
    static let dismissalAction = TVFullscreenDismissalAction.requestSwiftUICoverDismissal
    static let playerControllerDismissesItself = false
}
