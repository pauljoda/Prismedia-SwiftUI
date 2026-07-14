import CoreGraphics

enum EntityTagsPacking {
    static func rows(
        for itemWidths: [CGFloat],
        availableWidth: CGFloat,
        spacing: CGFloat
    ) -> [[Int]] {
        guard !itemWidths.isEmpty else { return [] }

        var rows = [[Int]]()
        var currentRow = [Int]()
        var currentWidth: CGFloat = 0

        for (index, itemWidth) in itemWidths.enumerated() {
            let requiredWidth = currentRow.isEmpty ? itemWidth : currentWidth + spacing + itemWidth
            if !currentRow.isEmpty, requiredWidth > availableWidth {
                rows.append(currentRow)
                currentRow = [index]
                currentWidth = itemWidth
                continue
            }

            currentRow.append(index)
            currentWidth = requiredWidth
        }

        if !currentRow.isEmpty { rows.append(currentRow) }
        return rows
    }
}
