import Foundation

struct EntityMonitorPresentation: Equatable, Sendable {
    let isOn: Bool?
    let isEnabled: Bool
    let isBusy: Bool
    let showsExpandedContent: Bool
    let canRetryCleanup: Bool
    let isAwaitingRefresh: Bool

    init(
        state: EntityMonitorState?,
        isMutating: Bool,
        pendingValue: Bool?,
        confirmedValue: Bool? = nil
    ) {
        isBusy = isMutating || pendingValue != nil || state == nil
        isAwaitingRefresh = confirmedValue != nil

        if let pendingValue {
            isOn = pendingValue
            isEnabled = false
            showsExpandedContent = false
            canRetryCleanup = false
            return
        }

        if let confirmedValue {
            isOn = confirmedValue
            isEnabled = false
            showsExpandedContent = confirmedValue
            canRetryCleanup = false
            return
        }

        guard let state else {
            isOn = nil
            isEnabled = false
            showsExpandedContent = false
            canRetryCleanup = false
            return
        }

        guard let monitor = state.monitor else {
            isOn = false
            isEnabled = state.canMonitor && !isMutating
            showsExpandedContent = false
            canRetryCleanup = false
            return
        }

        switch monitor.status {
        case .active:
            isOn = true
            isEnabled = !isMutating
            showsExpandedContent = !isMutating
            canRetryCleanup = false
        case .paused, .fulfilled:
            isOn = false
            isEnabled = !isMutating
            showsExpandedContent = false
            canRetryCleanup = false
        case .deletingFiles:
            isOn = true
            isEnabled = false
            showsExpandedContent = true
            canRetryCleanup = false
        case .stopping:
            isOn = false
            isEnabled = false
            showsExpandedContent = false
            canRetryCleanup = !isMutating
        default:
            isOn = nil
            isEnabled = false
            showsExpandedContent = false
            canRetryCleanup = false
        }
    }
}
