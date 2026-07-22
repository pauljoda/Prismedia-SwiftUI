import SwiftUI

#if os(iOS) || os(macOS)
    /// Compact transfer-piece availability map. Large client payloads are reduced to
    /// a stable number of cells while preserving missing, active, and completed runs.
    struct RequestActivityPieceStateBar: View {
        let pieces: [Int]

        var body: some View {
            if !cells.isEmpty {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Text("Piece availability")
                        .font(.caption2)
                        .foregroundStyle(PrismediaColor.textMuted)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 2) {
                        ForEach(Array(cells.enumerated()), id: \.offset) { _, state in
                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(color(for: state))
                                .frame(width: 5, height: 8)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Download piece availability")
                .accessibilityValue(accessibilityValue)
            }
        }

        private var columns: [GridItem] {
            [GridItem(.adaptive(minimum: 5, maximum: 5), spacing: 2)]
        }

        private var cells: [Int] {
            guard pieces.count > maximumCellCount else { return pieces }
            let piecesPerCell = Double(pieces.count) / Double(maximumCellCount)
            return (0..<maximumCellCount).map { index in
                let start = Int((Double(index) * piecesPerCell).rounded(.down))
                let end = Int((Double(index + 1) * piecesPerCell).rounded(.down))
                let range = pieces[start..<max(start + 1, end)]
                if range.allSatisfy({ $0 == 2 }) { return 2 }
                if range.contains(1) { return 1 }
                return 0
            }
        }

        private var accessibilityValue: String {
            let complete = pieces.count { $0 == 2 }
            let active = pieces.count { $0 == 1 }
            return "\(complete) of \(pieces.count) complete, \(active) downloading"
        }

        private func color(for state: Int) -> Color {
            switch state {
            case 2: PrismediaColor.accent
            case 1: PrismediaColor.warning
            default: PrismediaColor.controlFill
            }
        }

        private var maximumCellCount: Int { 160 }
    }

    #if DEBUG
        #Preview("Piece State Bar") {
            RequestActivityPieceStateBar(
                pieces: Array(repeating: 2, count: 24)
                    + Array(repeating: 1, count: 8)
                    + Array(repeating: 0, count: 24)
            )
            .padding()
        }
    #endif
#endif
