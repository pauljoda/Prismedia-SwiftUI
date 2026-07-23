import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestActivityAcquisitionLifecycleActions: View {
        let actions: [RequestActivityAcquisitionAction]
        let primaryAction: RequestActivityAcquisitionAction?
        let activeAction: RequestActivityAcquisitionAction?
        let primaryTint: Color
        let isDisabled: Bool
        let onPerform: (RequestActivityAcquisitionAction) -> Void

        var body: some View {
            PrismediaGlassButtonStack {
                ForEach(actions, id: \.self) { action in
                    PrismediaButton(
                        action.title,
                        systemImage: action.systemImage,
                        variant: variant(for: action),
                        form: .fill,
                        primaryTint: action == primaryAction ? primaryTint : nil,
                        isLoading: activeAction == action,
                        loadingTitle: action.progressTitle
                    ) {
                        onPerform(action)
                    }
                    .disabled(isDisabled)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
        }

        private func variant(
            for action: RequestActivityAcquisitionAction
        ) -> PrismediaButtonVariant {
            if action == primaryAction {
                return .prominent
            }
            return action == .cancel || action == .startOver
                ? .destructive
                : .standard
        }
    }

    #if DEBUG
        #Preview("Acquisition Lifecycle Actions · States") {
            RequestActivityAcquisitionLifecycleActions(
                actions: [.research, .cancel, .startOver],
                primaryAction: .research,
                activeAction: .research,
                primaryTint: PrismediaColor.spectrumCyan,
                isDisabled: false,
                onPerform: { _ in }
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }

        #Preview("Acquisition Lifecycle Actions · Accessibility") {
            RequestActivityAcquisitionLifecycleActions(
                actions: [.retryImport(allowFormatChange: false), .startOver],
                primaryAction: .retryImport(allowFormatChange: false),
                activeAction: nil,
                primaryTint: PrismediaColor.spectrumYellow,
                isDisabled: false,
                onPerform: { _ in }
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
            .dynamicTypeSize(.accessibility3)
        }
    #endif
#endif
