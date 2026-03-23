//
//  GradientView.swift
//  ColorWalk
//
//  CAGradientLayer 래퍼 뷰. ColorDetailViewController 등에서 공통 사용.
//

import UIKit

final class GradientView: UIView {

    private let gradientLayer = CAGradientLayer()

    /// - Parameters:
    ///   - colors: 그라디언트 색상 배열 (위→아래 순서)
    ///   - locations: 각 색상의 위치 (0.0~1.0), nil이면 균등 배분
    init(colors: [UIColor], locations: [NSNumber]? = nil) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        gradientLayer.colors    = colors.map { $0.cgColor }
        gradientLayer.locations = locations
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
