#if os(iOS) || os(macOS)
    import SwiftUI

    struct PDFReaderViewOptionsSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        @Binding var layoutMode: PDFReaderLayoutMode
        let fitMode: PDFReaderFitMode
        let onSelectFitMode: (PDFReaderFitMode) -> Void

        var body: some View {
            NavigationStack {
                Form {
                    Section("Reading Mode") {
                        Picker("Reading Mode", selection: $layoutMode) {
                            ForEach(PDFReaderLayoutMode.allCases) { mode in
                                Label(mode.label, systemImage: mode.systemImage).tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }

                    Section("Page Fit") {
                        ForEach(PDFReaderFitMode.allCases) { mode in
                            Button {
                                onSelectFitMode(mode)
                            } label: {
                                FullWidthButtonLabel {
                                    HStack {
                                        Label(mode.label, systemImage: mode.systemImage)
                                        Spacer()
                                        if mode == fitMode {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(artworkPrimaryAccent)
                                        }
                                    }
                                }
                            }
                            .accessibilityAddTraits(mode == fitMode ? .isSelected : [])
                        }
                    }
                }
                .formStyle(.grouped)
                .navigationTitle("View Options")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .accessibilityIdentifier("pdf-reader.view-options")
        }
    }

    #if DEBUG
        #Preview("PDF View Options") {
            @Previewable @State var layoutMode = PDFReaderLayoutMode.continuous
            PDFReaderViewOptionsSheet(
                layoutMode: $layoutMode,
                fitMode: .page,
                onSelectFitMode: { _ in }
            )
        }
    #endif
#endif
