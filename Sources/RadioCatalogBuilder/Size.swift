import Foundation

enum Size: String, CaseIterable {
    case xsmall = "xsmall"
    case small = "small"
    case medium = "medium"
    case large = "large"

    var limit: Int? {
        switch self {
        case .xsmall: return 50
        case .small: return 1_000
        case .medium: return 10_000
        case .large: return nil
        }
    }
}
