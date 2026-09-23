import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestBookRenditionOptionsView: View {
        let ebookRoots: [RequestLibraryRoot]
        let audiobookRoots: [RequestLibraryRoot]
        let profiles: [AdministrativeAcquisitionProfile]
        let isLoading: Bool
        let errorMessage: String?
        @Binding var selectedRenditions: Set<String>
        @Binding var ebookProfileID: UUID?
        @Binding var ebookRootID: UUID?
        @Binding var audiobookProfileID: UUID?
        @Binding var audiobookRootID: UUID?

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                Text("Formats")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textSecondary)
                Toggle("Ebook", isOn: selection(for: PrismediaContractCodes.BookRendition.ebook))
                Toggle("Audiobook", isOn: selection(for: PrismediaContractCodes.BookRendition.audiobook))

                if selectedRenditions.contains(PrismediaContractCodes.BookRendition.ebook) {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        Text("Ebook destination and profile")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                        RequestTargetOptionsView(
                            kind: .book,
                            roots: ebookRoots,
                            profiles: profiles,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            selectedProfileID: $ebookProfileID,
                            selectedRootID: $ebookRootID,
                            embedsInParentPanel: true
                        )
                    }
                }
                if selectedRenditions.contains(PrismediaContractCodes.BookRendition.audiobook) {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        Text("Audiobook destination and profile")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                        RequestTargetOptionsView(
                            kind: .audiobook,
                            roots: audiobookRoots,
                            profiles: profiles,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            selectedProfileID: $audiobookProfileID,
                            selectedRootID: $audiobookRootID,
                            embedsInParentPanel: true
                        )
                    }
                }
            }
        }

        private func selection(for rendition: String) -> Binding<Bool> {
            Binding(
                get: { selectedRenditions.contains(rendition) },
                set: { enabled in
                    if enabled {
                        selectedRenditions.insert(rendition)
                    } else if selectedRenditions.count > 1 {
                        selectedRenditions.remove(rendition)
                    }
                }
            )
        }
    }
#endif
