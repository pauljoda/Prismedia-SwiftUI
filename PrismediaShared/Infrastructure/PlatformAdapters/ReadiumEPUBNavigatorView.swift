#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    @MainActor
    struct ReadiumEPUBNavigatorView: UIViewControllerRepresentable {
        let host: ReadiumEPUBNavigatorHostController
        let isSwipeDownEnabled: Bool
        let onSwipeDown: () -> Void

        init(
            host: ReadiumEPUBNavigatorHostController,
            isSwipeDownEnabled: Bool = false,
            onSwipeDown: @escaping () -> Void = {}
        ) {
            self.host = host
            self.isSwipeDownEnabled = isSwipeDownEnabled
            self.onSwipeDown = onSwipeDown
        }

        func makeUIViewController(context: Context) -> ReadiumEPUBNavigatorHostController {
            configure(host)
            return host
        }

        func updateUIViewController(
            _ uiViewController: ReadiumEPUBNavigatorHostController,
            context: Context
        ) {
            configure(uiViewController)
        }

        private func configure(_ controller: ReadiumEPUBNavigatorHostController) {
            controller.isSwipeDownEnabled = isSwipeDownEnabled
            controller.onSwipeDown = onSwipeDown
        }
    }

    #if DEBUG
        #Preview("Readium EPUB Navigator") {
            ReadiumEPUBNavigatorView(host: ReadiumEPUBNavigatorHostController())
        }
    #endif
#endif
