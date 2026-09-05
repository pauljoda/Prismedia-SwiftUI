import SwiftUI

#if os(tvOS)
    /// Native playback-entry action. Primary playback has stronger emphasis than
    /// alternatives such as restarting; the system owns sizing and focus growth.
    struct TVPlaybackLaunchButton: View {
        let title: String
        let systemImage: String
        let isPrimary: Bool
        let action: () -> Void

        var body: some View {
            Group {
                if isPrimary {
                    button
                        .buttonStyle(.glassProminent)
                        .foregroundStyle(PrismediaColor.onAccent)
                } else {
                    button.buttonStyle(.glass)
                }
            }
            .controlSize(.regular)
            .buttonBorderShape(.capsule)
        }

        private var button: some View {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(PrismediaTypography.sectionTitle)
            }
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Playback Actions") {
        HStack(spacing: PrismediaSpacing.section) {
            TVPlaybackLaunchButton(title: "Resume", systemImage: "play.fill", isPrimary: true) {}
            TVPlaybackLaunchButton(
                title: "Play from Beginning", systemImage: "backward.end.fill", isPrimary: false
            ) {}
        }
        .padding(PrismediaSpacing.section)
        .preferredColorScheme(.dark)
    }
#endif
