#if os(tvOS)
import SwiftUI

struct EntityDetailPlatformHeroStack<Hero: View, Playback: View>: View {
    let showsHeroArtwork: Bool
    @ViewBuilder let hero: () -> Hero
    @ViewBuilder let playback: () -> Playback

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
            if !showsHeroArtwork {
                Color.clear
                    .frame(height: 120)
                    .accessibilityHidden(true)
            }
            hero()
            playback()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("TV Entity Detail Hero") {
    EntityDetailPlatformHeroStack(
        showsHeroArtwork: true,
        hero: { Text("Signal in the Static").font(.largeTitle) },
        playback: { Color.black.frame(height: 240) }
    )
    .padding(72)
}
#endif
