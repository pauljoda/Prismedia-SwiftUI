import Foundation

extension Bundle {
    static var prismediaResources: Bundle {
        #if SWIFT_PACKAGE
            .module
        #else
            .main
        #endif
    }
}
