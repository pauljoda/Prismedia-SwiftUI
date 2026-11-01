import SwiftUI

extension EnvironmentValues {
    /// How many list columns share the scroll view's width, so a list row's
    /// artwork stays a fixed share of its own column rather than of the page.
    @Entry var entityListColumnCount = 1
}
