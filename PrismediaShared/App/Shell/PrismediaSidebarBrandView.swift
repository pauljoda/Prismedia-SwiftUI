import SwiftUI

struct PrismediaSidebarBrandView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment

    let markSize: CGFloat
    var subtitle: String?

    var body: some View {
        HStack(spacing: PrismediaSpacing.medium) {
            PrismediaBrandView(
                markSize: markSize,
                isDecorative: true,
                usesNsfwMark: environment.allowsNsfwContent
            )
            .contentTransition(.opacity)

            VStack(alignment: .leading, spacing: 1) {
                Text("PRISMEDIA")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .tracking(1.5)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(PrismediaColor.textMuted)
                }
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.65, perform: toggleNsfwContent)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("shell.sidebar.brand")
        .accessibilityLabel(
            environment.allowsNsfwContent
                ? "Prismedia, NSFW content visible"
                : "Prismedia"
        )
        .accessibilityValue(environment.allowsNsfwContent ? "NSFW content visible" : "SFW content only")
        .accessibilityHint(nsfwAccessibilityHint)
        .accessibilityAction(named: "Toggle NSFW Content", toggleNsfwContent)
    }

    private var nsfwAccessibilityHint: String {
        guard environment.session?.user.allowNsfw == true else { return "" }
        return "Long press the logo to toggle NSFW content visibility."
    }

    private func toggleNsfwContent() {
        guard environment.session?.user.allowNsfw == true else { return }
        environment.setAllowsNsfwContent(!environment.allowsNsfwContent)
    }
}

#if DEBUG
    #Preview("Sidebar Brand · SFW") {
        PrismediaSidebarBrandView(markSize: 30, subtitle: "Media, in one place")
            .environment(PrismediaPreviewData.model(signedIn: true))
            .padding()
            .background(PrismediaColor.background)
    }
#endif
