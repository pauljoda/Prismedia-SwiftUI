#if os(macOS)
    import SwiftUI

    struct MacPrismediaSidebarView: View {
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Binding var selection: AppSidebarSelection?
        @State private var hoveredItemID: String?

        let sections: [AppSidebarSection]

        var body: some View {
            VStack(spacing: 0) {
                brandHeader

                List {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Section {
                            ForEach(section.items) { item in
                                sidebarRow(
                                    item,
                                    accent: PrismediaSidebarPalette.accent(
                                        for: section.id,
                                        fallbackIndex: index
                                    )
                                )
                            }
                        } header: {
                            Text(section.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(
                                    PrismediaSidebarPalette.accent(
                                        for: section.id,
                                        fallbackIndex: index
                                    )
                                )
                                .textCase(.uppercase)
                                .tracking(0.8)
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                accountFooter
            }
            .background(.ultraThinMaterial)
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

        private func sidebarRow(_ item: AppSidebarItem, accent: Color) -> some View {
            let isSelected = selection == item.selection
            let isHovered = hoveredItemID == item.id

            return Button {
                selection = item.selection
            } label: {
                HStack(spacing: PrismediaSpacing.small) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isSelected ? accent : .clear)
                        .frame(width: 3, height: 18)

                    Image(systemName: item.systemImage)
                        .frame(width: 18)
                        .foregroundStyle(isSelected ? PrismediaColor.textPrimary : accent)

                    Text(item.title)
                        .foregroundStyle(
                            isSelected ? PrismediaColor.textPrimary : PrismediaColor.textSecondary
                        )

                    Spacer(minLength: 0)
                }
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, PrismediaSpacing.small)
                .frame(maxWidth: .infinity, minHeight: PrismediaLayout.minimumHitTarget)
                .background(
                    isSelected || isHovered
                        ? PrismediaColor.controlFill.opacity(isSelected ? 0.72 : 0.36)
                        : .clear,
                    in: .rect(cornerRadius: PrismediaRadius.compact)
                )
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: PrismediaRadius.compact)
                            .stroke(PrismediaColor.borderSubtle, lineWidth: PrismediaLayout.hairline)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8))
            .listRowBackground(Color.clear)
            .onHover { isHovering in
                hoveredItemID = isHovering ? item.id : nil
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("sidebar.\(item.id)")
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
