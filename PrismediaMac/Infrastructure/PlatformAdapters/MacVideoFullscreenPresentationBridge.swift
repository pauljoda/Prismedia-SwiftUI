#if os(macOS)
    import AppKit
    import SwiftUI

    struct MacVideoFullscreenPresentationBridge<FullscreenContent: View>: NSViewRepresentable {
        let isPresented: Bool
        let fullscreenContent: FullscreenContent
        let windowController: MacVideoFullscreenWindowController
        let onDismiss: () -> Void

        func makeNSView(context: Context) -> NSView {
            NSView(frame: .zero)
        }

        func updateNSView(_ view: NSView, context: Context) {
            if isPresented {
                windowController.presentOrUpdate(
                    content: AnyView(fullscreenContent),
                    onDismiss: onDismiss
                )
            } else {
                windowController.requestDismissal()
            }
        }
    }

    #if DEBUG
        #Preview("Inactive Fullscreen Presentation Bridge") {
            MacVideoFullscreenPresentationBridge(
                isPresented: false,
                fullscreenContent: Color.black,
                windowController: MacVideoFullscreenWindowController(),
                onDismiss: {}
            )
            .frame(width: 320, height: 180)
        }
    #endif
#endif
