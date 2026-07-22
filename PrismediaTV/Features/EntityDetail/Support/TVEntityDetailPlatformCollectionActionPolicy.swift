#if os(tvOS)
    enum EntityDetailPlatformCollectionActionPolicy {
        static func adapt(_ policy: EntityGridActionPolicy) -> EntityGridActionPolicy {
            EntityGridActionPolicy(
                selectionEnabled: false,
                builtInActions: [.addToCollection]
            )
        }

        static func mutationService(
            _ service: (any EntityGridMutationServicing)?
        ) -> (any EntityGridMutationServicing)? {
            service
        }
    }
#endif
