//
//  ColorDotView.swift
//  ColorWalk
//
//  단색 원형 색상 점. GlassOverlay, DetailVC 등에서 공통 사용.
//

import UIKit
import SnapKit

final class ColorDotView: UIView {

    /// - Parameters:
    ///   - size: 지름 (pt)
    ///   - borderColor: 선택적 테두리 색
    ///   - borderWidth: 테두리 두께 (기본 0)
    init(size: CGFloat, borderColor: UIColor? = nil, borderWidth: CGFloat = 0) {
        super.init(frame: .zero)
        layer.cornerRadius = size / 2
        if let borderColor {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = borderWidth
        }
        snp.makeConstraints { $0.width.height.equalTo(size) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setColor(_ color: UIColor) {
        backgroundColor = color
    }
}
