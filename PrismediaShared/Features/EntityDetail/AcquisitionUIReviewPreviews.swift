#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    // One-off visual review catalog for the Acquisition UI redesign.
    //
    // Each focused Acquisition pass appends a named, deterministic `#Preview`
    // for every visual state and component it introduces. Keep all fixtures
    // in-memory so the complete flow can be reviewed without a live server.
    #Preview("Acquisition UI Review · Index") {
        ContentUnavailableView {
            Label("Acquisition UI Review", systemImage: "rectangle.stack")
        } description: {
            Text("Use the named previews in this file to inspect every Acquisition state.")
        }
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
