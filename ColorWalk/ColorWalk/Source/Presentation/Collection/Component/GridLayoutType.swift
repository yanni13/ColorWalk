import Foundation
import CoreGraphics

enum GridLayoutType: CaseIterable {
    case twoByTwo
    case threeByThree
    case twoByThree
    case filmStrip

    var displayTitle: String {
        switch self {
        case .twoByTwo:     return "2×2 정방형"
        case .threeByThree: return "3×3 그리드"
        case .twoByThree:   return "2×3 세로형"
        case .filmStrip:    return "필름 스트립"
        }
    }

    /// photoGridView의 height = width × multiplier
    var aspectRatioMultiplier: CGFloat {
        switch self {
        case .twoByTwo:     return 1.0
        case .threeByThree: return 1.0
        case .twoByThree:   return 1.0
        case .filmStrip:    return 1.13
        }
    }

    var iconSystemName: String {
        switch self {
        case .twoByTwo:     return "square.grid.2x2"
        case .threeByThree: return "square.grid.3x3"
        case .twoByThree:   return "rectangle.grid.2x2"
        case .filmStrip:    return "film"
        }
    }
}
