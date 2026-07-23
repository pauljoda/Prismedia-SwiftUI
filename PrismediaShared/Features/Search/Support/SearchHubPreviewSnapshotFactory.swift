#if DEBUG
    enum SearchHubPreviewSnapshotFactory {
        static func loading(query: String) -> SearchHubSnapshot {
            var snapshot = SearchHubSnapshot()
            _ = snapshot.beginSearch(query: query)
            return snapshot
        }

        static func content(
            query: String,
            items: [EntityThumbnail] = PrismediaPreviewData.allEntities
        ) -> SearchHubSnapshot {
            var snapshot = SearchHubSnapshot()
            let request = snapshot.beginSearch(query: query)!
            _ = snapshot.receiveSearch(
                SearchHubPage(
                    items: items,
                    totalCount: items.count,
                    nextCursor: nil
                ),
                for: request,
                currentQuery: query
            )
            return snapshot
        }

        static func empty(query: String) -> SearchHubSnapshot {
            content(query: query, items: [])
        }

        static func failed(query: String) -> SearchHubSnapshot {
            var snapshot = SearchHubSnapshot()
            let request = snapshot.beginSearch(query: query)!
            _ = snapshot.failSearch(for: request, currentQuery: query)
            return snapshot
        }
    }
#endif
