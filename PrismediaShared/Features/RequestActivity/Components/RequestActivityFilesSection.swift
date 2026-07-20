import SwiftUI

#if os(iOS) || os(macOS)
    /// The embedded downloaded/imported files block. Collapsible, and collapses itself
    /// once the acquisition reports its files as imported so a big pack doesn't fill
    /// the panel — matching the web's collapse-once-imported behavior.
    struct RequestActivityFilesSection: View {
        let files: RequestActivityFiles?
        let isActive: Bool
        @State private var isExpanded = true

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                if let files, !files.files.isEmpty {
                    DisclosureGroup(isExpanded: $isExpanded) {
                        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                            ForEach(files.files, id: \.name) { file in
                                fileRow(file)
                            }
                        }
                        .padding(.top, PrismediaSpacing.small)
                    } label: {
                        header(count: files.files.count)
                    }
                    .onChange(of: files.imported, initial: true) { _, imported in
                        isExpanded = !imported
                    }
                } else {
                    header(count: nil)
                    RequestActivityStatePlaceholder(
                        title: "No files yet",
                        message: "Files will appear here once the download produces them.",
                        systemImage: "doc.text",
                        isBusy: isActive
                    )
                }
            }
        }

        private func header(count: Int?) -> some View {
            HStack(spacing: PrismediaSpacing.small) {
                Text("Files")
                    .font(.headline)
                    .foregroundStyle(PrismediaColor.textPrimary)
                if let count {
                    Text(String(count))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                }
            }
            .accessibilityAddTraits(.isHeader)
        }

        private func fileRow(_ file: RequestActivityFile) -> some View {
            HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                Label {
                    Text(file.name)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "doc.text")
                        .foregroundStyle(PrismediaColor.textMuted)
                }
                Spacer(minLength: PrismediaSpacing.small)
                Text(RequestActivityFormatting.bytes(file.sizeBytes))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .accessibilityElement(children: .combine)
        }
    }

    #if DEBUG
        #Preview("Files Section") {
            VStack(spacing: PrismediaSpacing.large) {
                RequestActivityFilesSection(
                    files: RequestActivityPreviewFixtures.files,
                    isActive: true
                )
                RequestActivityFilesSection(files: nil, isActive: false)
            }
            .padding()
        }
    #endif
#endif
