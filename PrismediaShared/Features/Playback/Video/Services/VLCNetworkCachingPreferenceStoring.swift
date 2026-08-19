import Foundation

@MainActor
protocol VLCNetworkCachingPreferenceStoring {
    func loadSeconds() -> Int
    func saveSeconds(_ seconds: Int)
}
