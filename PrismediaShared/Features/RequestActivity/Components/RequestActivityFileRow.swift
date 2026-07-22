import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityFileRow: View {
        let file: RequestActivityFile
        @State private var showsDetails = false

        var body: some View {
            DisclosureGroup(isExpanded: $showsDetails) {
                RequestActivityFileDetails(file: file)
                    .padding(.top, PrismediaSpacing.small)
            } label: {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                        fileName
                        Spacer(minLength: PrismediaSpacing.small)
                        status
                        size
                    }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        fileName
                        HStack(spacing: PrismediaSpacing.small) { status; size }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel("\(file.name), \(RequestActivityFilesPresentationPolicy.statusLabel(for: file)), \(RequestActivityFormatting.bytes(file.sizeBytes))")
        }

        private var fileName: some View {
            Text(file.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PrismediaColor.textPrimary)
                .lineLimit(nil)
                .textSelection(.enabled)
        }

        private var status: some View {
            Text(RequestActivityFilesPresentationPolicy.statusLabel(for: file))
                .font(.caption.weight(.semibold))
                .foregroundStyle(file.status?.value == .failed ? PrismediaColor.destructive : PrismediaColor.textSecondary)
        }

        private var size: some View {
            Text(RequestActivityFormatting.bytes(file.sizeBytes))
                .font(.caption.monospacedDigit())
                .foregroundStyle(PrismediaColor.textMuted)
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Acquisition Review · Files · Row Component") {
        RequestActivityFileRow(file: RequestActivityFile(
            id: "row-preview", name: "Dune.epub", sizeBytes: 4_200_000, progress: 1,
            sourceRelativePath: "Dune Retail/Dune.epub",
            destinationRelativePath: "Books/Frank Herbert/Dune/Dune.epub",
            role: .init(value: .media), contentKind: .init(value: .book),
            status: .init(value: .imported), decision: .init(value: .placeNew), technicalError: nil
        ))
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }
#endif
