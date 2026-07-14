import Foundation

enum VideoScalingMode: String, CaseIterable, Identifiable {
    case fit, fill
    var id: Self { self }
    var label: String { rawValue.capitalized }
}
