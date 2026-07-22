#if os(iOS)
import SwiftUI

struct EntityDetailPlatformHeroStack<Hero: View, Playback: View>: View {
    let showsHeroArtwork: Bool
    @ViewBuilder let hero: () -> Hero
    @ViewBuilder let playback: () -> Playback

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            playback()
            hero()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("iOS Entity Detail Hero") {
    EntityDetailPlatformHeroStack(
        showsHeroArtwork: true,
        hero: { Text("Signal in the Static").font(.largeTitle) },
        playback: { Color.black.frame(height: 180) }
    )
    .padding()
}
#endif
