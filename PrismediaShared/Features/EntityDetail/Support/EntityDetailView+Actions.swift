import SwiftUI

extension EntityDetailView {
    var detailHorizontalPadding: CGFloat {
        #if os(tvOS)
            PrismediaLayout.televisionContentInset
        #else
            PrismediaSpacing.extraLarge
        #endif
    }

    func isEnabled(_ action: EntityDetailAction) -> Bool {
        if action.id == .identify {
            #if os(iOS) || os(macOS)
                return dependencies.identify != nil
                    && !identifyAvailability.isChecking
                    && identifyPresentation == nil
            #else
                return false
            #endif
        }
        if action.id == .audio {
            #if os(iOS) || os(macOS)
                return currentDetail?.kind == .collection
                    && dependencies.collectionItemsLoader != nil
            #else
                return false
            #endif
        }
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
        if action.id == .identify {
            #if os(iOS) || os(macOS)
                return dependencies.identify != nil
            #else
                return false
            #endif
        }
        if action.id == .audio {
            #if os(iOS) || os(macOS)
                return currentDetail?.kind == .collection
                    && dependencies.collectionItemsLoader != nil
            #else
                return false
            #endif
        }
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
        case .audio:
            #if os(iOS) || os(macOS)
                guard case .content(let detail) = state.phase,
                    detail.kind == .collection,
                    dependencies.collectionItemsLoader != nil
                else { return }
                advancedEntityLink = EntityLink(
                    entityID: detail.id,
                    kind: detail.kind,
                    parentEntityID: link.parentEntityID,
                    parentKind: link.parentKind,
                    intent: .audioCollection,
                    sourceThumbnail: link.sourceThumbnail,
                    thumbnailPreview: link.thumbnailPreview,
                    mediaSequence: link.mediaSequence
                )
            #endif
        case .edit:
            guard case .content(let detail) = state.phase,
                dependencies.metadataMutator != nil,
                dependencies.entityGridLoader != nil
            else { return }
            editPresentation = EntityDetailEditPresentation(detail: detail)
        case .identify:
            #if os(iOS) || os(macOS)
                guard case .content(let detail) = state.phase,
                    let identify = dependencies.identify
                else { return }

                if identifyAvailability.routesToProviders {
                    identify.onOpenProviders()
                    return
                }
                guard !identifyAvailability.isChecking else { return }

                let session = IdentifySession(
                    service: identify.administration,
                    browser: identify.browser,
                    hidesNsfw: identify.hidesNsfw,
                    initialQueue: identifyAvailability.initialQueue,
                    initialProviders: identifyAvailability.initialProviders,
                    initialEntityDetail: detail
                )
                identifyPresentation = IdentifyEntryPresentation(
                    entityID: detail.id,
                    session: session
                )
                identifyEntryTask = Task {
                    await session.beginEntry(entityID: detail.id)
                }
            #endif
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
        if action.id == .audio {
            return isEnabled(action)
                ? "Opens Play and Shuffle controls for audio in this collection"
                : "Audio playback is unavailable for this collection"
        }
        if action.id == .edit {
            return isEnabled(action)
                ? "Opens the Main and Metadata editor"
                : "Editing requires taxonomy search to be available"
        }
        if action.id == .identify {
            #if os(iOS) || os(macOS)
                if identifyAvailability.isChecking {
                    return "Checking the identify queue and compatible plugins"
                }
                if identifyAvailability.routesToProviders {
                    return "Opens Plugins because no compatible Identify plugin is ready"
                }
                if case .queued = identifyAvailability {
                    return "Resumes this item from the durable Identify queue"
                }
                return "Adds this item to the Identify queue and opens metadata search"
            #else
                return "Identify is unavailable on Apple TV"
            #endif
        }
        return isEnabled(action)
            ? "Updates this entity"
            : "This action is not available in the native app yet"
    }

    #if os(iOS) || os(macOS)
        func refreshIdentifyAvailability(
            for detail: EntityDetail
        ) async {
            guard detail.hasSourceMedia,
                EntityDetailPresentation(detail: detail).flagCapability?.isWanted != true,
                let identify = dependencies.identify
            else {
                identifyAvailability = .unavailable
                return
            }

            let next = await EntityIdentifyAvailabilityService(
                administration: identify.administration,
                hidesNsfw: identify.hidesNsfw
            ).load(
                entityID: detail.id,
                kind: detail.kind
            )
            guard !Task.isCancelled, currentDetail?.id == detail.id else { return }
            identifyAvailability = next
        }
    #endif

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
            .environment(\.artworkPalette, artworkPalette)
            .environment(
                \.artworkPrimaryAccent,
                artworkPalette?.primary.color ?? PrismediaColor.accent
            )
            .environment(
                \.artworkSecondaryText,
                artworkPalette?.secondary.color ?? PrismediaColor.textSecondary
            )
        }
    }
}
