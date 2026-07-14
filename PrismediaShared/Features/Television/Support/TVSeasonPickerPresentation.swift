import Foundation

enum TVSeasonPickerPresentation {
    static func isSelected(
        seasonID: UUID,
        selectedSeasonID: UUID?
    ) -> Bool {
        seasonID == selectedSeasonID
    }
}
