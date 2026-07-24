import Foundation

#if os(iOS) || os(macOS)
    enum IdentifyChildReviewPolicy {
        static func items(
            children: [EntityThumbnail],
            proposal: AdministrativeEntityMetadataProposal,
            cascadeRunning: Bool
        ) -> [IdentifyChildReviewItem] {
            let descendants = MetadataReviewPolicy.structuralDescendants(of: proposal)
            let proposalsByEntityID = descendants.reduce(
                into: [UUID: AdministrativeEntityMetadataProposal]()
            ) { proposals, child in
                guard let targetEntityID = child.targetEntityID,
                    proposals[targetEntityID] == nil
                else { return }
                proposals[targetEntityID] = child
            }
            let lastMatchedIndex =
                children.lastIndex {
                    proposalsByEntityID[$0.id] != nil
                } ?? -1

            return children.enumerated().map { index, entity in
                let matchedProposal = proposalsByEntityID[entity.id]
                return IdentifyChildReviewItem(
                    entity: entity,
                    proposal: matchedProposal,
                    state: state(
                        hasMatch: matchedProposal != nil,
                        index: index,
                        lastMatchedIndex: lastMatchedIndex,
                        cascadeRunning: cascadeRunning
                    )
                )
            }
        }

        static func newContainers(
            in proposal: AdministrativeEntityMetadataProposal
        ) -> [AdministrativeEntityMetadataProposal] {
            MetadataReviewPolicy.structuralChildren(of: proposal).filter { child in
                child.targetEntityID == nil
                    && MetadataReviewPolicy.structuralDescendants(of: child).contains {
                        $0.targetEntityID != nil
                    }
            }
        }

        static func remainingChildren(
            _ children: [EntityThumbnail],
            in proposal: AdministrativeEntityMetadataProposal
        ) -> [EntityThumbnail] {
            let adoptedIDs = Set(
                newContainers(in: proposal)
                    .flatMap { MetadataReviewPolicy.structuralDescendants(of: $0) }
                    .compactMap(\.targetEntityID)
            )
            return children.filter { !adoptedIDs.contains($0.id) }
        }

        private static func state(
            hasMatch: Bool,
            index: Int,
            lastMatchedIndex: Int,
            cascadeRunning: Bool
        ) -> IdentifyChildReviewState {
            if hasMatch {
                return .matched
            }
            guard cascadeRunning else {
                return .noMatch
            }
            if index <= lastMatchedIndex {
                return .noMatch
            }
            if index == lastMatchedIndex + 1 {
                return .loading
            }
            return .queued
        }
    }
#endif
