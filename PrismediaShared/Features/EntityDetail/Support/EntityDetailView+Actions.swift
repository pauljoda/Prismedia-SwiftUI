import SwiftUI

extension EntityDetailView {
    var detailHorizontalPadding: CGFloat {
        #if os(tvOS)
            72
        #else
            20
        #endif
    }

    func isEnabled(_ action: EntityDetailAction) -> Bool {
        if action.id == .edit {
            return !state.isMutating
                && dependencies.metadataMutator != nil
                && dependencies.entityGridLoader != nil
        }
        if action.id == .listen {
            #if os(iOS) || os(macOS)
                return audiobookProjection != nil
                    && !isAudiobookLoading
                    && !isListeningMutating
                    && dependencies.audioPlaybackService != nil
            #else
                return false
            #endif
        }
        if action.id == .read || action.id == .resume {
            #if os(tvOS)
                return false
            #else
                return readingService.isAvailable && currentBookUsesNativeReader
            #endif
        }
        guard !state.isMutating, service.canMutate else { return false }
        return isSupported(action)
    }

    func isSupported(_ action: EntityDetailAction) -> Bool {
        if action.id == .edit {
            #if os(tvOS)
                return false
            #else
                return dependencies.metadataMutator != nil
            #endif
        }
        if action.id == .listen {
            #if os(iOS) || os(macOS)
                return audiobookProjection != nil
            #else
                return false
            #endif
        }
        if action.id == .read || action.id == .resume {
            #if os(tvOS)
                return false
            #else
                return readingService.isAvailable
            #endif
        }
        return action.id == .favorite || action.id == .organized
    }

    func perform(_ action: EntityDetailAction) {
        switch action.id {
        case .favorite:
            Task {
                if await toggleFlag(.favorite) {
                    dependencies.onEntityMutated()
                }
            }
        case .organized:
            Task {
                if await toggleFlag(.organized) {
                    dependencies.onEntityMutated()
                }
            }
        case .read:
            if readingState.requiresResetBeforeReading {
                Task { await startReadingOver(openReaderWhenReady: true) }
            } else {
                openReader(command: .read)
            }
        case .resume:
            openReader(command: .resume)
        case .listen:
            #if os(iOS) || os(macOS)
                guard case .content(let detail) = state.phase else { return }
                let presentation = audiobookPresentation(for: detail)
                if presentation?.actionTitle == "Pause" {
                    musicPlayer.pause()
                } else {
                    beginListening(to: detail)
                }
            #endif
        case .edit:
            guard case .content(let detail) = state.phase,
                dependencies.metadataMutator != nil,
                dependencies.entityGridLoader != nil
            else { return }
            editPresentation = EntityDetailEditPresentation(detail: detail)
        default:
            break
        }
    }

    func accessibilityLabel(for action: EntityDetailAction) -> String {
        switch action.id {
        case .favorite:
            action.isSelected ? "Remove from favorites" : "Add to favorites"
        case .organized:
            action.isSelected ? "Mark as unorganized" : "Mark as organized"
        default:
            action.title
        }
    }

    func accessibilityHint(for action: EntityDetailAction) -> String {
        if action.id == .listen {
            return isEnabled(action)
                ? "Plays this audiobook in the native audio player"
                : "This audiobook is still preparing"
        }
        if action.id == .read || action.id == .resume {
            return isEnabled(action)
                ? "Opens the native reader"
                : "This item cannot be opened in the native reader"
        }
        if action.id == .edit {
            return isEnabled(action)
                ? "Opens the Main and Metadata editor"
                : "Editing requires taxonomy search to be available"
        }
        return isEnabled(action)
            ? "Updates this entity"
            : "This action is not available in the native app yet"
    }

    @ViewBuilder
    func editSheet(
        for presentation: EntityDetailEditPresentation
    ) -> some View {
        if let metadataMutator = dependencies.metadataMutator,
            let entityGridLoader = dependencies.entityGridLoader
        {
            EntityDetailEditSheet(
                presentation: presentation,
                service: EntityDetailEditService(
                    metadataMutator: metadataMutator,
                    userMetadataMutator: dependencies.mutator
                ),
                referenceLoader: entityGridLoader,
                onSaved: {
                    await loadDetail()
                    dependencies.onEntityMutated()
                }
            )
        }
    }
}
