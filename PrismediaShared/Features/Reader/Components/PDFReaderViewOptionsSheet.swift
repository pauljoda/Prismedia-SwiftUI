#if os(iOS) || os(macOS)
    import SwiftUI

    struct PDFReaderViewOptionsSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.artworkPalette) private var artworkPalette
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

        @Binding var layoutMode: PDFReaderLayoutMode
        @Binding var pageLayout: PDFReaderPageLayout
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

                    #if os(iOS)
                        Section("Page Layout") {
                            Picker("Page Layout", selection: $pageLayout) {
                                ForEach(PDFReaderPageLayout.allCases) { layout in
                                    Label(layout.label, systemImage: layout.systemImage).tag(layout)
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                            .accessibilityIdentifier("pdf-reader.view-options.page-layout")
                        }
                    #endif

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
                .prismediaScreenBackground(palette: artworkPalette)
                .formStyle(.grouped)
                .navigationTitle("View Options")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        PrismediaToolbarActionButton("Done", systemImage: "checkmark") { dismiss() }
                    }
                }
            }
            .accessibilityIdentifier("pdf-reader.view-options")
        }
    }

    #if DEBUG
        #Preview("PDF View Options") {
            @Previewable @State var layoutMode = PDFReaderLayoutMode.continuous
            @Previewable @State var pageLayout = PDFReaderPageLayout.automatic
            PDFReaderViewOptionsSheet(
                layoutMode: $layoutMode,
                pageLayout: $pageLayout,
                fitMode: .page,
                onSelectFitMode: { _ in }
            )
        }
    #endif
#endif
