#if os(macOS)
    import AppKit
    import SwiftUI

    /// Frees Command-Shift-Z for Prismedia's cross-platform content-mode shortcut.
    /// Undo keeps its native shortcut; Redo remains available at Command-Y.
    @MainActor
    struct PrismediaMacUndoRedoCommands: Commands {
        var body: some Commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo", systemImage: "arrow.uturn.backward") {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo", systemImage: "arrow.uturn.forward") {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                .keyboardShortcut("y", modifiers: .command)
            }
        }
    }
#endif
