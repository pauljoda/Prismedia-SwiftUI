#if !os(tvOS)
    import AVFoundation
    import SwiftAssRenderer
    import SwiftUI

    struct VideoAssSubtitleOverlay: View {
        let contents: String
        let player: AVPlayer

        @State private var renderer: AssSubtitlesRenderer

        init(contents: String, player: AVPlayer) {
            self.contents = contents
            self.player = player
            let fontsPath = Bundle.main.resourceURL ?? URL(fileURLWithPath: "/")
            _renderer = State(
                initialValue: AssSubtitlesRenderer(
                    fontConfig: FontConfig(
                        fontsPath: fontsPath,
                        fontProvider: .coreText
                    )
                )
            )
        }

        var body: some View {
            AssSubtitles(renderer: renderer)
                .attach(
                    player: player,
                    updateInterval: CMTime(value: 1, timescale: 10)
                )
                .allowsHitTesting(false)
                .onAppear { renderer.loadTrack(content: contents) }
                .onChange(of: contents) { _, contents in
                    renderer.reloadTrack(content: contents)
                }
                .onDisappear { renderer.freeTrack() }
                .accessibilityHidden(true)
        }
    }

    #if DEBUG
        #Preview("ASS Subtitle Overlay") {
            ZStack {
                Color.black
                VideoAssSubtitleOverlay(
                    contents: """
                        [Script Info]
                        ScriptType: v4.00+
                        PlayResX: 1920
                        PlayResY: 1080

                        [V4+ Styles]
                        Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
                        Style: Default,Arial,54,&H00FFFFFF,&H000000FF,&H00000000,&H64000000,0,0,0,0,100,100,0,0,1,3,1,2,60,60,70,1

                        [Events]
                        Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
                        Dialogue: 0,0:00:00.00,0:01:00.00,Default,,0,0,0,,Styled subtitle preview
                        """,
                    player: AVPlayer()
                )
            }
        }
    #endif
#endif
