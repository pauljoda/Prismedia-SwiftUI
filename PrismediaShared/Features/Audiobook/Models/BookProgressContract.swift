import Foundation

/// How the connected server keeps a Book's reading and listening progress.
enum BookProgressContract: Equatable, Sendable {
    /// Servers from 3.8 own alignment and resume, and record one exact checkpoint per modality.
    case serverAlignment
    /// Older servers keep one shared cursor; the app aligns positions with its legacy resolvers.
    case legacyCursor
}
