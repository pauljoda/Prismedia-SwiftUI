#if os(macOS)
    import SwiftUI

    struct MacPrismediaSidebarView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Binding var selection: AppSidebarSelection?

        let sections: [AppSidebarSection]

        var body: some View {
            VStack(spacing: 0) {
                brandHeader

                List(selection: $selection) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Section {
                            ForEach(section.items) { item in
                                Label {
                                    Text(item.title)
                                } icon: {
                                    Image(systemName: item.systemImage)
                                        .foregroundStyle(
                                            PrismediaSidebarPalette.accent(
                                                for: section.id,
                                                fallbackIndex: index
                                            )
                                        )
                                }
                                .tag(item.selection)
                                .accessibilityIdentifier("sidebar.\(item.id)")
                            }
                        } header: {
                            Text(section.title)
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                accountFooter
            }
            .background(.ultraThinMaterial)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: MacNavigationSidebarWidthPreferenceKey.self,
                        value: proxy.size.width
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 208, ideal: 232, max: 284)
            .accessibilityIdentifier("shell.sidebar")
        }

        private var brandHeader: some View {
            PrismediaSidebarBrandView(
                markSize: 30,
                subtitle: "Media, in one place"
            )
            .padding(.horizontal, PrismediaSpacing.large)
            .padding(.top, PrismediaSpacing.medium)
            .padding(.bottom, PrismediaSpacing.small)
        }

        private var accountFooter: some View {
            Group {
                if let user = environment.session?.user {
                    HStack(spacing: PrismediaSpacing.small) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(PrismediaColor.materialSpectrumViolet)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(user.displayName.isEmpty ? user.username : user.displayName)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text(user.role.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(PrismediaColor.textMuted)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, PrismediaSpacing.large)
                    .padding(.vertical, PrismediaSpacing.medium)
                    .background(PrismediaColor.background.opacity(0.28))
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(PrismediaColor.borderSubtle)
                            .frame(height: PrismediaLayout.hairline)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }

    }

    #if DEBUG
        #Preview("Mac Sidebar") {
            @Previewable @State var environment = PrismediaPreviewData.model(signedIn: true)
            @Previewable @State var selection: AppSidebarSelection? =
                .destination(modeID: "overview", destinationID: "dashboard")

            MacPrismediaSidebarView(
                selection: $selection,
                sections: AppSidebarCatalog.sections(for: PrismediaPreviewData.user)
            )
            .environment(environment)
            .frame(width: 232, height: 760)
        }
    #endif
#endif
