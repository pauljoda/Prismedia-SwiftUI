import SwiftUI

struct DashboardHeroProgressIndicator: View {
    let presentations: [DashboardHeroPresentation]
    let sceneCounts: [Int]
    let position: DashboardHeroPosition
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

                        if index == position.itemIndex {
                            Capsule()
                                .fill(accent)
                                .frame(width: selectedWidth * sceneProgress(at: index))
                        }
                    }
                    .frame(
                        width: index == position.itemIndex ? selectedWidth : unselectedWidth,
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
                .accessibilityValue(accessibilityValue(at: index))
                .accessibilityAddTraits(index == position.itemIndex ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Featured media")
    }

    private let selectedWidth: CGFloat = 38
    private let unselectedWidth: CGFloat = 10
    private let indicatorHeight: CGFloat = 6

    private func sceneProgress(at index: Int) -> Double {
        let sceneCount = sceneCount(at: index)
        let scene = min(max(position.sceneIndex, 0), sceneCount - 1)
        return Double(scene + 1) / Double(sceneCount)
    }

    private func accessibilityValue(at index: Int) -> String {
        let page = "Featured \(index + 1) of \(presentations.count)"
        guard index == position.itemIndex else { return page }
        return "\(page), scene \(position.sceneIndex + 1) of \(sceneCount(at: index))"
    }

    private func sceneCount(at index: Int) -> Int {
        guard sceneCounts.indices.contains(index) else { return 1 }
        return max(sceneCounts[index], 1)
    }
}

#if DEBUG
    #Preview("Dashboard Hero Progress") {
        DashboardHeroProgressIndicator(
            presentations: PrismediaPreviewData.videos.map(DashboardHeroPresentation.init),
            sceneCounts: PrismediaPreviewData.videos.map {
                DashboardHeroPresentation(item: $0).sceneCount
            },
            position: DashboardHeroPosition(itemIndex: 0, sceneIndex: 0),
            accent: PrismediaColor.spectrumCyan,
            onSelect: { _ in }
        )
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
