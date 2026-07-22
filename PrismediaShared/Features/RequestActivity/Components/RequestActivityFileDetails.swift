import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityFileDetails: View {
        let file: RequestActivityFile

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                if let path = file.sourceRelativePath { detail("Source", value: path, copy: true) }
                if let path = file.destinationRelativePath { detail("Destination", value: path, copy: true) }
                if let role = file.role { detail("Role", value: role.rawValue.capitalized) }
                if let kind = file.contentKind { detail("Content", value: kind.rawValue.capitalized) }
                if let decision = file.decision {
                    detail("Decision", value: RequestActivityFilesPresentationPolicy.decisionLabel(for: decision))
                }
                if let error = file.technicalError { detail("Technical Error", value: error, copy: true) }
            }
        }

        private func detail(_ label: String, value: String, copy: Bool = false) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(label).font(.caption.weight(.semibold)).foregroundStyle(PrismediaColor.textMuted)
                HStack(alignment: .top, spacing: PrismediaSpacing.small) {
                    Text(value)
                        .font(.callout)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if copy {
                        Button("Copy", systemImage: "doc.on.doc") { PrismediaClipboard.copy(value) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Copy \(label.lowercased())")
                    }
                }
            }
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Acquisition Review · Files · Details Component") {
        RequestActivityFileDetails(file: RequestActivityFile(
            id: "detail-preview", name: "Dune.epub", sizeBytes: 4_200_000, progress: 1,
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
