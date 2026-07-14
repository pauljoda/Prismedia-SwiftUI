import SwiftUI

/// Artwork-driven atmosphere for music browsing inside the fixed dark app chrome.
struct MusicBrowseBackdrop<Content: View>: View {
    @Binding private var palette: ArtworkPalette?
    let artworkPath: String?
    let previewPath: String?
    let fallbackSeed: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(
        artworkPath: String?,
        previewPath: String?,
        fallbackSeed: String,
        systemImage: String,
        palette: Binding<ArtworkPalette?>,
        @ViewBuilder content: () -> Content
    ) {
        self.artworkPath = artworkPath
        self.previewPath = previewPath
        self.fallbackSeed = fallbackSeed
        self.systemImage = systemImage
        _palette = palette
        self.content = content()
    }

    var body: some View {
        ArtworkPaletteSurface(
            artworkPath: artworkPath,
            previewPath: previewPath,
            fallbackSeed: fallbackSeed,
            systemImage: systemImage,
            palette: $palette
        ) {
            content
        }
    }
}

extension MusicBrowseBackdrop where Content == EmptyView {
    init(
        artworkPath: String?,
        previewPath: String?,
        fallbackSeed: String,
        systemImage: String
    ) {
        self.init(
            artworkPath: artworkPath,
            previewPath: previewPath,
            fallbackSeed: fallbackSeed,
            systemImage: systemImage,
            palette: .constant(nil)
        ) {
            EmptyView()
        }
    }
}

#if DEBUG
    #Preview("Music Browse Atmosphere · Dark") {
        PreviewShell {
            ZStack {
                MusicBrowseBackdrop(
                    artworkPath: nil,
                    previewPath: nil,
                    fallbackSeed: "Midnight Sessions",
                    systemImage: "music.note"
                )
                Text("Midnight Sessions")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
            }
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Music Browse Atmosphere · Accessibility") {
        PreviewShell {
            ZStack {
                MusicBrowseBackdrop(
                    artworkPath: nil,
                    previewPath: nil,
                    fallbackSeed: "Accessible Sessions",
                    systemImage: "music.note"
                )
                Text("A Longer Adaptive Music Title")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
