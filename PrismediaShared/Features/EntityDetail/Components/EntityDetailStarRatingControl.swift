import SwiftUI

struct EntityDetailStarRatingControl: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    let value: Int?
    let isDisabled: Bool
    let onChange: (Int?) -> Void

    var body: some View {
        HStack(spacing: starSpacing) {
            ForEach(1...5, id: \.self) { rating in
                Button {
                    onChange(value == rating ? nil : rating)
                } label: {
                    Image(systemName: rating <= (value ?? 0) ? "star.fill" : "star")
                        .font(starFont)
                        .foregroundStyle(artworkPrimaryAccent)
                        .frame(width: starHitSize, height: starHitSize)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .accessibilityLabel("Rate \(rating)")
                .accessibilityValue(rating <= (value ?? 0) ? "Selected" : "Not selected")
                .accessibilityIdentifier("entity-detail.rating.\(rating)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rating")
    }

    private var starSpacing: CGFloat {
        #if os(tvOS)
            14
        #else
            4
        #endif
    }

    private var starHitSize: CGFloat {
        #if os(tvOS)
            56
        #else
            40
        #endif
    }

    private var starFont: Font {
        #if os(tvOS)
            .title2.weight(.semibold)
        #else
            .title3.weight(.semibold)
        #endif
    }
}
#if DEBUG
    #Preview("Star Rating") {
        EntityDetailStarRatingControl(value: 4, isDisabled: false, onChange: { _ in })
            .padding()
    }
#endif
