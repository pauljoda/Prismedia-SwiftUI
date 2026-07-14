import SwiftUI

struct VideoSubtitleOverlay: View {
    let content: VideoSubtitleText
    let appearance: VideoSubtitleAppearance

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                caption
                    .frame(maxWidth: proxy.size.width * 0.86)
                    .padding(.bottom, proxy.size.height * appearance.bottomInsetFraction)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(appearance.opacity)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: content.plainText))
        .accessibilityIdentifier("video-player.subtitle")
    }

    @ViewBuilder
    private var caption: some View {
        let label = Text(attributedCaption)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .foregroundStyle(PrismediaColor.onMedia)

        switch appearance.style {
        case .stylized:
            label
                .padding(.horizontal, PrismediaSpacing.large)
                .padding(.vertical, PrismediaSpacing.small)
                .background(Color(hex: 0x08090C, opacity: 0.78), in: .rect(cornerRadius: PrismediaRadius.badge))
                .overlay {
                    RoundedRectangle(cornerRadius: PrismediaRadius.badge)
                        .stroke(PrismediaColor.spectrumCyan.opacity(0.25), lineWidth: PrismediaLayout.hairline)
                }
                .shadow(color: .black.opacity(0.5), radius: 8)
                .shadow(color: PrismediaColor.spectrumCyan.opacity(0.08), radius: 12)
        case .classic:
            label
                .foregroundStyle(Color(white: 0.95))
                .padding(.horizontal, PrismediaSpacing.medium)
                .padding(.vertical, PrismediaSpacing.extraSmall)
                .background(.black.opacity(0.78), in: .rect(cornerRadius: PrismediaRadius.badge))
                .shadow(color: .black.opacity(0.9), radius: 1, y: 1)
        case .outline:
            label
                .shadow(color: .black.opacity(0.95), radius: 0, x: -1, y: -1)
                .shadow(color: .black.opacity(0.95), radius: 0, x: 1, y: -1)
                .shadow(color: .black.opacity(0.95), radius: 0, x: -1, y: 1)
                .shadow(color: .black.opacity(0.95), radius: 0, x: 1, y: 1)
                .shadow(color: .black.opacity(0.9), radius: 3)
        }
    }

    private var attributedCaption: AttributedString {
        content.runs.reduce(into: AttributedString()) { result, run in
            var fragment = AttributedString(run.text)
            var font = Font.system(
                size: baseFontSize * appearance.fontScale,
                weight: run.style.contains(.bold) ? .bold : .medium
            )
            if run.style.contains(.italic) { font = font.italic() }
            fragment.font = font
            if run.style.contains(.underline) { fragment.underlineStyle = .single }
            result.append(fragment)
        }
    }

    private var baseFontSize: CGFloat {
        #if os(tvOS)
            42
        #else
            17
        #endif
    }
}

#if DEBUG
    #Preview("Subtitle Appearance") {
        VideoSubtitleOverlay(
            content: VideoSubtitleText("This is how your subtitles will look."),
            appearance: .default
        )
        .aspectRatio(16 / 9, contentMode: .fit)
        .background {
            LinearGradient(
                colors: [Color(hex: 0x1A1F2B), Color(hex: 0x0E1118), Color(hex: 0x2A1F14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
#endif
