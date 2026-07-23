import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityAcquisitionActionMenu: View {
        let lifecycleActions: [RequestActivityAcquisitionAction]
        let showsDeleteFiles: Bool
        let isLifecycleDisabled: Bool
        let isDeleteFilesDisabled: Bool
        let onPerform: (RequestActivityAcquisitionAction) -> Void
        let onDeleteFiles: () -> Void

        var body: some View {
            PrismediaButton(
                "Acquisition actions",
                systemImage: "ellipsis",
                form: .compactIcon,
                menuContent: {
                    if !lifecycleActions.isEmpty {
                        Section("Acquisition") {
                            ForEach(lifecycleActions, id: \.self) { action in
                                Button(
                                    action.title,
                                    systemImage: action.systemImage,
                                    role: action == .cancel ? .destructive : nil
                                ) {
                                    onPerform(action)
                                }
                                .disabled(isLifecycleDisabled)
                            }
                        }
                    }

                    if showsDeleteFiles {
                        Section("Library") {
                            Button(
                                "Delete Files",
                                systemImage: "trash",
                                role: .destructive,
                                action: onDeleteFiles
                            )
                            .disabled(isDeleteFilesDisabled)
                        }
                    }
                }
            )
            .disabled(
                (lifecycleActions.isEmpty || isLifecycleDisabled)
                    && (!showsDeleteFiles || isDeleteFilesDisabled)
            )
            .prismediaCompactActionControlSize()
        }
    }

    #if DEBUG
        #Preview("Acquisition Actions Menu") {
            RequestActivityAcquisitionActionMenu(
                lifecycleActions: [.cancel],
                showsDeleteFiles: true,
                isLifecycleDisabled: false,
                isDeleteFilesDisabled: false,
                onPerform: { _ in },
                onDeleteFiles: {}
            )
            .padding()
            .preferredColorScheme(.dark)
        }
    #endif
#endif
