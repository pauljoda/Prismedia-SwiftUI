import SwiftUI

enum EntityDetailHeroArtworkPolicy {
    /// Dedicated API backdrop artwork fills the decorative wide hero frame.
    /// Poster and thumbnail assets never enter this surface.
    static let contentMode: ContentMode = .fill
    static let summaryLineLimit = 6

    /// Only dedicated API backdrop artwork may create a full-width detail
    /// atmosphere. Posters remain discrete header artwork.
    static func atmospherePath(heroPath: String?) -> String? {
        heroPath
    }
}
