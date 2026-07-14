import SwiftUI

extension View {
    @ViewBuilder
    public func prismediaAdaptiveAppTabStyle() -> some View {
        #if os(iOS) || os(macOS)
            self.tabViewStyle(.sidebarAdaptable)
        #else
            self
        #endif
    }

    @ViewBuilder
    public func prismediaInlineNavigationTitle() -> some View {
        #if os(iOS)
            self.navigationBarTitleDisplayMode(.inline)
        #else
            self
        #endif
    }

    @ViewBuilder
    public func prismediaPlainTextInput() -> some View {
        #if os(iOS) || os(tvOS)
            self.textInputAutocapitalization(.never)
        #else
            self
        #endif
    }

    @ViewBuilder
    public func prismediaCredentialTextInput() -> some View {
        #if os(iOS)
            self
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        #elseif os(tvOS)
            // tvOS disables its ABC keyboard mode when capitalization is `.never`.
            // Sentences keeps the system's ABC/abc selector enabled; secure entry
            // still controls masking and never applies autocorrection.
            self
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
        #else
            self
        #endif
    }

    @ViewBuilder
    public func prismediaKeyboardDismissal() -> some View {
        #if os(iOS)
            self.scrollDismissesKeyboard(.interactively)
        #else
            self
        #endif
    }

    @ViewBuilder
    public func prismediaTextSelection() -> some View {
        #if os(tvOS)
            self
        #else
            self.textSelection(.enabled)
        #endif
    }

    @ViewBuilder
    public func prismediaFocusSection() -> some View {
        #if os(tvOS)
            self.focusSection()
        #else
            self
        #endif
    }

    @ViewBuilder
    public func prismediaEntityNavigationButtonStyle() -> some View {
        #if os(tvOS)
            self.buttonStyle(.card)
        #else
            self.buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    public func prismediaDetailTabButtonStyle() -> some View {
        #if os(tvOS)
            self.buttonStyle(.glass)
        #else
            self.buttonStyle(.plain)
        #endif
    }
}

#if DEBUG
    #Preview("Platform Navigation & Input") {
        @Previewable @State var serverURL = "localhost:8008"

        TabView {
            Tab("Connection", systemImage: "network") {
                NavigationStack {
                    Form {
                        Section("Server") {
                            TextField("Server URL", text: $serverURL)
                                .prismediaPlainTextInput()
                                .prismediaTextInputStyle()

                            SecureField("API key", text: .constant("preview-key"))
                                .prismediaCredentialTextInput()
                                .prismediaTextInputStyle()
                        }

                        Section("Actions") {
                            Button("Open entity") {}
                                .prismediaEntityNavigationButtonStyle()
                            Button("Show details") {}
                                .prismediaDetailTabButtonStyle()
                        }

                        Text(serverURL)
                            .foregroundStyle(.secondary)
                            .prismediaTextSelection()
                    }
                    .prismediaKeyboardDismissal()
                    .prismediaFocusSection()
                    .navigationTitle("Connection")
                    .prismediaInlineNavigationTitle()
                }
            }
        }
        .prismediaAdaptiveAppTabStyle()
        .tint(PrismediaColor.accent)
    }
#endif
