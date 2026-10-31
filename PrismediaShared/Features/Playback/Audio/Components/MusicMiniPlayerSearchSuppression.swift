import SwiftUI

/// Suppresses the regular-width mini player while the enclosing search is
/// active. On compact width the mini player is the tab accessory, which the
/// system already arranges around search.
struct MusicMiniPlayerSearchSuppression: View {
    @Environment(\.isSearching) private var isSearching
    @Environment(\.musicMiniPlayerVisibility) private var visibility
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var suppressionID = UUID()

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .onChange(of: suppresses, initial: true) { _, suppresses in
                if suppresses {
                    visibility?.suppress(id: suppressionID)
                } else {
                    visibility?.restore(id: suppressionID)
                }
            }
            .onDisappear {
                visibility?.restore(id: suppressionID)
            }
    }

    private var suppresses: Bool {
        #if os(iOS)
            isSearching && horizontalSizeClass == .regular
        #else
            false
        #endif
    }
}
