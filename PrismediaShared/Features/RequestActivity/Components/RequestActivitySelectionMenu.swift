import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivitySelectionMenu: View {
        let section: RequestActivitySection
        let selectedCount: Int
        let onRemove: () -> Void
        let onSearch: () -> Void
        let onUnmonitor: () -> Void

        var body: some View {
            Menu {
                if section == .downloads {
                    Button("Remove Selected", systemImage: "trash", role: .destructive, action: onRemove)
                } else {
                    Button("Search Selected", systemImage: "arrow.clockwise", action: onSearch)
                    Button(
                        "Unmonitor Selected",
                        systemImage: "bell.slash",
                        role: .destructive,
                        action: onUnmonitor
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("Selected Item Actions")
            .accessibilityValue("\(selectedCount) selected")
        }
    }

    #if DEBUG
        #Preview("Request Activity Selection Actions") {
            PrismediaGlassButtonGroup(spacing: PrismediaSpacing.medium) {
                RequestActivitySelectionMenu(
                    section: .downloads,
                    selectedCount: 2,
                    onRemove: {},
                    onSearch: {},
                    onUnmonitor: {}
                )
                RequestActivitySelectionMenu(
                    section: .missing,
                    selectedCount: 3,
                    onRemove: {},
                    onSearch: {},
                    onUnmonitor: {}
                )
            }
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    #endif
#endif
