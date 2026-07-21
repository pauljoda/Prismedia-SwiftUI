import SwiftUI

#if os(tvOS)

    struct TVSeasonPicker: View {
        let seasons: [EntityThumbnail]
        let selectedSeasonID: UUID?
        let onSelect: (EntityThumbnail) -> Void

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PrismediaSpacing.extraLarge) {
                    ForEach(seasons) { season in
                        let isSelected = TVSeasonPickerPresentation.isSelected(
                            seasonID: season.id,
                            selectedSeasonID: selectedSeasonID
                        )
                        Button {
                            onSelect(season)
                        } label: {
                            Text(season.title)
                        }
                        .font(.system(size: 20, weight: .semibold))
                        .controlSize(.small)
                        .buttonStyle(.glass)
                        .tvSeasonSelectionTint(isSelected)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityValue(isSelected ? "Selected" : "")
                        .accessibilityIdentifier("tv.seasons-detail.season.\(season.id.uuidString)")
                    }
                }
                .padding(.horizontal, 72)
                .padding(.vertical, PrismediaSpacing.medium)
            }
            .prismediaFocusSection()
        }
    }

    extension View {
        @ViewBuilder
        fileprivate func tvSeasonSelectionTint(_ isSelected: Bool) -> some View {
            if isSelected {
                tint(PrismediaColor.accent)
            } else {
                self
            }
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Season Picker · Selected · Accessibility Type") {
        let seasons = [
            TVSeasonsPreviewData.seasonThumbnail,
            EntityThumbnail(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555556")!,
                kind: .videoSeason,
                title: "Season 2",
                parentEntityID: TVSeasonsPreviewData.seriesID,
                sortOrder: 2
            ),
        ]

        PreviewShell {
            TVSeasonPicker(
                seasons: seasons,
                selectedSeasonID: TVSeasonsPreviewData.seasonID,
                onSelect: { _ in }
            )
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
