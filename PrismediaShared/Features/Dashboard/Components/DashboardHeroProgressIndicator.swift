import SwiftUI

struct DashboardHeroProgressIndicator: View {
    let presentations: [DashboardHeroPresentation]
    let selectedIndex: Int
    let accent: Color
    let onSelect: (UUID) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(presentations.enumerated()), id: \.element.id) { index, presentation in
                Button {
                    onSelect(presentation.id)
                } label: {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(PrismediaColor.onMedia.opacity(0.3))

                        if index == selectedIndex {
                            Capsule()
                                .fill(accent)
                                .frame(width: selectedWidth)
                        }
                    }
                    .frame(
                        width: index == selectedIndex ? selectedWidth : unselectedWidth,
                        height: indicatorHeight
                    )
                    .frame(
                        minWidth: PrismediaLayout.minimumHitTarget,
                        minHeight: PrismediaLayout.minimumHitTarget
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(presentation.item.title)
                .accessibilityValue("Featured \(index + 1) of \(presentations.count)")
                .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Featured media")
    }

    private let selectedWidth: CGFloat = 38
    private let unselectedWidth: CGFloat = 10
    private let indicatorHeight: CGFloat = 6

}

#if DEBUG
    #Preview("Dashboard Hero Progress") {
        DashboardHeroProgressIndicator(
            presentations: PrismediaPreviewData.videos.map(DashboardHeroPresentation.init),
            selectedIndex: 0,
            accent: PrismediaColor.spectrumCyan,
            onSelect: { _ in }
        )
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
