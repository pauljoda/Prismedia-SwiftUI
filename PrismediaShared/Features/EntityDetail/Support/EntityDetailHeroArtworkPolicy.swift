import SwiftUI

enum EntityDetailHeroArtworkPolicy {
    /// Dedicated API backdrop artwork fills the decorative wide hero frame.
    /// Poster and thumbnail assets never enter this surface.
    static let contentMode: ContentMode = .fill
    static let summaryLineLimit = 6

    /// The full detail atmosphere prefers the sharp hero's source, while a
    /// poster remains a safe fallback without becoming a synthetic hero.
    static func atmospherePath(heroPath: String?, posterPath: String?) -> String? {
        heroPath ?? posterPath
    }
}
