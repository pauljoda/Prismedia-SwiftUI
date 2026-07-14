import SwiftUI

struct AdministrativeSubtitlePreview: View {
    let settings: [AdministrativeSetting]

    var body: some View {
        Section("Preview") {
            VideoSubtitleOverlay(
                content: VideoSubtitleText("This is how your subtitles will look."),
                appearance: appearance
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            .background {
                LinearGradient(
                    colors: [.indigo.opacity(0.65), .black, .brown.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(.rect(cornerRadius: PrismediaRadius.control))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Subtitle style preview")
        }
    }

    private var appearance: VideoSubtitleAppearance {
        let fallback = VideoSubtitleAppearance.default
        let style =
            value(for: "subtitles.style")?.stringValue
            .flatMap(VideoSubtitleDisplayStyle.init(rawValue:)) ?? fallback.style
        return VideoSubtitleAppearance(
            style: style,
            fontScale: value(for: "subtitles.fontScale")?.numberValue ?? fallback.fontScale,
            positionPercent: value(for: "subtitles.positionPercent")?.numberValue ?? fallback.positionPercent,
            opacity: value(for: "subtitles.opacity")?.numberValue ?? fallback.opacity
        )
    }

    private func value(for key: String) -> AdministrativeJSONValue? {
        settings.first { $0.key == key }?.value
    }
}

#if DEBUG
    #Preview("Subtitle Preview") {
        Form {
            AdministrativeSubtitlePreview(settings: [])
        }
    }
#endif
