import SwiftUI

struct EntityTagsFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let idealSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let availableWidth = proposal.width ?? unconstrainedWidth(for: idealSizes)
        let sizes = measuredSizes(subviews, constrainedTo: availableWidth)
        let rows = EntityTagsPacking.rows(
            for: sizes.map(\.width), availableWidth: availableWidth, spacing: horizontalSpacing)
        let height = rows.enumerated().reduce(CGFloat.zero) { total, entry in
            let rowHeight = entry.element.map { sizes[$0].height }.max() ?? 0
            return total + rowHeight + (entry.offset == 0 ? 0 : verticalSpacing)
        }
        return CGSize(width: availableWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = measuredSizes(subviews, constrainedTo: bounds.width)
        let rows = EntityTagsPacking.rows(
            for: sizes.map(\.width), availableWidth: bounds.width, spacing: horizontalSpacing)
        var y = bounds.minY

        for row in rows {
            let rowHeight = row.map { sizes[$0].height }.max() ?? 0
            var x = bounds.minX
            for index in row {
                subviews[index].place(
                    at: CGPoint(x: x, y: y + ((rowHeight - sizes[index].height) / 2)),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(sizes[index])
                )
                x += sizes[index].width + horizontalSpacing
            }
            y += rowHeight + verticalSpacing
        }
    }

    private func unconstrainedWidth(for sizes: [CGSize]) -> CGFloat {
        sizes.map(\.width).reduce(0, +) + CGFloat(max(0, sizes.count - 1)) * horizontalSpacing
    }

    private func measuredSizes(_ subviews: Subviews, constrainedTo width: CGFloat) -> [CGSize] {
        subviews.map { subview in
            let idealSize = subview.sizeThatFits(.unspecified)
            guard idealSize.width > width else { return idealSize }
            return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
        }
    }
}

#if DEBUG
    #Preview("Tag Flow Layout") {
        EntityTagsFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(
                ["Science Fiction", "Space Opera", "Adventure", "Found Family"],
                id: \.self
            ) { title in
                Text(title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, PrismediaSpacing.small)
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                    .background(PrismediaColor.controlFill, in: .capsule)
            }
        }
        .frame(width: 260, alignment: .leading)
        .padding()
        .background(PrismediaBackdrop())
    }
#endif
