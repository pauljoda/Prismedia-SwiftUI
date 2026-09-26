import SwiftUI

struct BookChapterMappingEditorRow: View {
    let number: Int
    let audioChapter: BookAudioChapter
    let chapters: [ReadableBookChapter]
    let automaticChapterTitle: String?
    /// How the draft pair was confirmed, when the audio chapter is paired in the draft.
    let origin: BookChapterMappingOrigin?
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
                    Text(audioChapter.title)
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textMuted)
                }
            }

            Picker("Readable chapter for \(audioChapter.title)", selection: $selection) {
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
        automaticChapterTitle.map { String(localized: "Exact title: \($0)") } ?? String(localized: "Not paired")
    }

    /// Where the pair comes from: a person's pick, a reviewed in-order fill, or an exact title match.
    private var status: String {
        guard selection != nil else {
            return automaticChapterTitle == nil
                ? String(localized: "Unmatched") : String(localized: "Matched by exact title")
        }
        return origin == .ordered ? String(localized: "Filled in order") : String(localized: "Picked by hand")
    }
}
