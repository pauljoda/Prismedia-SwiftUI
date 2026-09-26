#if os(iOS) && canImport(ReadiumNavigator)
    import Foundation
    @preconcurrency import ReadiumNavigator

    /// Reports touch, pointer, and key input inside the Readium navigator without consuming it.
    ///
    /// The EPUB session treats any input as the start of reader movement; the position Readium
    /// reports next is then the reader's choice rather than a programmatic settle.
    @MainActor
    final class ReadiumEPUBInputActivityObserver: InputObserving {
        // MARK: - Variables

        private let onInput: @MainActor () -> Void

        // MARK: - Initializers

        init(onInput: @escaping @MainActor () -> Void) {
            self.onInput = onInput
        }

        // MARK: - Actions - Input

        func didReceive(_ event: PointerEvent) async -> Bool {
            onInput()
            return false
        }

        func didReceive(_ event: KeyEvent) async -> Bool {
            onInput()
            return false
        }
    }
#endif
