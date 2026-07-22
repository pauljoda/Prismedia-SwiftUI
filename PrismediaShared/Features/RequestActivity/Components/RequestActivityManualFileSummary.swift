import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityManualFileSummary: View {
        let files: [RequestActivityManualUploadFile]
        let onRemove: (RequestActivityManualUploadFile) -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Label(files.count == 1 ? "Selected File" : "Selected Files", systemImage: "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: PrismediaSpacing.small)
                    Text(RequestActivityManualUploadPolicy.summary(for: files))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                }

                ForEach(Array(files.prefix(visibleFileLimit))) { file in
                    HStack(spacing: PrismediaSpacing.small) {
                        Image(systemName: "doc")
                            .foregroundStyle(PrismediaColor.textMuted)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Text(file.fileName)
                                .lineLimit(2)
                                .textSelection(.enabled)
                            Text(ByteCountFormatter.string(fromByteCount: file.sizeBytes, countStyle: .file))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(PrismediaColor.textMuted)
                        }
                        Spacer(minLength: PrismediaSpacing.small)
                        Button("Remove \(file.fileName)", systemImage: "xmark", role: .cancel) {
                            onRemove(file)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(PrismediaColor.textSecondary)
                    }
                    .accessibilityElement(children: .contain)
                }

                if files.count > visibleFileLimit {
                    Text("\(files.count - visibleFileLimit) more files selected")
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textMuted)
                }
            }
            .padding(PrismediaSpacing.medium)
            .prismediaPanel()
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(files.count == 1 ? "Selected file" : "Selected files")
            .accessibilityValue(RequestActivityManualUploadPolicy.summary(for: files))
        }

        private var visibleFileLimit: Int { 4 }
    }

    #if DEBUG
        #Preview("Manual File Summary") {
            RequestActivityManualFileSummary(
                files: [
                    RequestActivityManualUploadFile(
                        url: URL(fileURLWithPath: "/preview/Dune.epub"),
                        fileName: "Dune.epub",
                        sizeBytes: 4_200_000
                    )
                ],
                onRemove: { _ in }
            )
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
