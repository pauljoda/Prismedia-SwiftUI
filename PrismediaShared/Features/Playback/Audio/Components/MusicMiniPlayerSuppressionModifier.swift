import Foundation
import SwiftUI

struct MusicMiniPlayerSuppressionModifier: ViewModifier {
    @Environment(\.musicMiniPlayerVisibility) private var visibility
    @State private var suppressionID = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear {
                visibility?.suppress(id: suppressionID)
            }
            .onDisappear {
                visibility?.restore(id: suppressionID)
            }
    }
}

extension View {
    func suppressesMusicMiniPlayer() -> some View {
        modifier(MusicMiniPlayerSuppressionModifier())
    }
}

#if DEBUG
    #Preview("Mini Player Suppression") {
        @Previewable @State var visibility = MusicMiniPlayerVisibility()
        Color.black
            .overlay {
                Text("Immersive Media")
                    .foregroundStyle(PrismediaColor.onMedia)
            }
            .modifier(MusicMiniPlayerSuppressionModifier())
            .environment(\.musicMiniPlayerVisibility, visibility)
    }
#endif
