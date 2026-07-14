import Foundation

#if os(iOS) || os(macOS)
    enum PluginSearchPresentationState: Equatable, Sendable {
        case noProvider
        case preSearch
        case searching
        case noResults
        case results(count: Int)
        case error(message: String)

        static func resolve(
            hasProvider: Bool,
            isSearching: Bool,
            hasSearched: Bool,
            candidateCount: Int,
            errorMessage: String?
        ) -> PluginSearchPresentationState {
            if let errorMessage, !errorMessage.isEmpty {
                return .error(message: errorMessage)
            }
            guard hasProvider else { return .noProvider }
            if isSearching { return .searching }
            guard hasSearched else { return .preSearch }
            return candidateCount == 0 ? .noResults : .results(count: candidateCount)
        }
    }
#endif
