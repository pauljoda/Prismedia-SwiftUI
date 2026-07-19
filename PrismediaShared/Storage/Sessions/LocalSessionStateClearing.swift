import Foundation

@MainActor
public protocol LocalSessionStateClearing: AnyObject {
    func clear() async
}
