#if os(macOS)
    import AppKit
    import SwiftUI

    @MainActor
    final class MacVideoFullscreenWindowController: NSObject, NSWindowDelegate {
        private weak var returnWindow: NSWindow?
        private var fullscreenWindow: NSWindow?
        private var hostingController: NSHostingController<AnyView>?
        private var onDismiss: (() -> Void)?
        private var isEnteringFullscreen = false
        private var isRequestingDismissal = false

        func presentOrUpdate(
            content: AnyView,
            onDismiss: @escaping () -> Void
        ) {
            self.onDismiss = onDismiss

            if let hostingController {
                hostingController.rootView = content
                return
            }

            let hostingController = NSHostingController(rootView: content)
            let screen = NSApp.keyWindow?.screen ?? NSScreen.main
            let initialFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1_280, height: 800)
            let window = NSWindow(
                contentRect: initialFrame,
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.contentViewController = hostingController
            window.backgroundColor = .black
            window.collectionBehavior = [.fullScreenPrimary, .fullScreenDisallowsTiling]
            window.isReleasedWhenClosed = false
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.delegate = self

            returnWindow = NSApp.keyWindow
            fullscreenWindow = window
            self.hostingController = hostingController
            isEnteringFullscreen = true
            isRequestingDismissal = false

            window.makeKeyAndOrderFront(nil)
            window.toggleFullScreen(nil)
        }

        func requestDismissal() {
            guard let window = fullscreenWindow, !isRequestingDismissal else { return }
            isRequestingDismissal = true

            if window.styleMask.contains(.fullScreen) || isEnteringFullscreen {
                window.toggleFullScreen(nil)
            } else {
                finishPresentation(window: window)
            }
        }

        func closeImmediately() {
            guard let window = fullscreenWindow else { return }
            finishPresentation(window: window)
        }

        func windowDidEnterFullScreen(_ notification: Notification) {
            guard notification.object as? NSWindow === fullscreenWindow else { return }
            isEnteringFullscreen = false
        }

        func windowDidExitFullScreen(_ notification: Notification) {
            guard let window = notification.object as? NSWindow, window === fullscreenWindow else {
                return
            }
            finishPresentation(window: window)
        }

        func windowDidFailToEnterFullScreen(_ window: NSWindow) {
            guard window === fullscreenWindow else { return }
            finishPresentation(window: window)
        }

        func windowWillClose(_ notification: Notification) {
            guard let window = notification.object as? NSWindow, window === fullscreenWindow else {
                return
            }
            finishPresentation(window: window)
        }

        private func finishPresentation(window: NSWindow) {
            guard window === fullscreenWindow else { return }

            let dismissal = onDismiss
            let returnWindow = returnWindow
            onDismiss = nil
            isEnteringFullscreen = false
            isRequestingDismissal = false
            hostingController = nil
            fullscreenWindow = nil
            self.returnWindow = nil

            window.delegate = nil
            window.orderOut(nil)
            window.close()
            returnWindow?.makeKeyAndOrderFront(nil)
            dismissal?()
        }
    }
#endif
