struct SearchHubTaskID: Hashable {
    let query: String
    let filters: SearchHubFilterState
    let revision: Int
}
