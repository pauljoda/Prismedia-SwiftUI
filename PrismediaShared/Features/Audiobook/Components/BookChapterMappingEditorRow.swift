import SwiftUI

struct BookChapterMappingEditorRow: View {
    let number: Int
    let track: MusicTrack
    let chapters: [ReadableBookChapter]
    let automaticChapterTitle: String?
    let isDisabled: Bool
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                Text(number, format: .number.precision(.integerLength(2)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textMuted)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                    Text(track.title)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(selection == nil ? "Automatic title matching" : "Explicit mapping")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textMuted)
                }
            }

            Picker("Readable chapter for \(track.title)", selection: $selection) {
                Text(automaticSelectionTitle)
                    .tag(String?.none)
                ForEach(chapters) { chapter in
                    Text(chapter.title)
                        .tag(Optional(chapter.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .disabled(isDisabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(PrismediaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var automaticSelectionTitle: String {
        automaticChapterTitle.map { "Automatic: \($0)" } ?? "No explicit mapping"
    }
}
