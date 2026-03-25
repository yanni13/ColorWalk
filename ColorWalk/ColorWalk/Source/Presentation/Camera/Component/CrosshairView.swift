//
//  CrosshairView.swift
//  ColorWalk
//

import UIKit

final class CrosshairView: UIView {

    private let circleLayer  = CAShapeLayer()
    private let hLeftLayer   = CAShapeLayer()
    private let hRightLayer  = CAShapeLayer()
    private let vTopLayer    = CAShapeLayer()
    private let vBottomLayer = CAShapeLayer()
    private let dotLayer     = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let arms = [hLeftLayer, hRightLayer, vTopLayer, vBottomLayer]
        arms.forEach {
            $0.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
            $0.fillColor   = UIColor.clear.cgColor
            $0.lineWidth   = 1.5
            $0.lineCap     = .round
            layer.addSublayer($0)
        }
        circleLayer.strokeColor = UIColor.white.withAlphaComponent(0.45).cgColor
        circleLayer.fillColor   = UIColor.clear.cgColor
        circleLayer.lineWidth   = 1.0
        layer.addSublayer(circleLayer)

        dotLayer.fillColor   = UIColor.white.cgColor
        dotLayer.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(dotLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cx: CGFloat = bounds.midX
        let cy: CGFloat = bounds.midY
        let arm: CGFloat = 16
        let gap: CGFloat = 7

        // Outer ring
        circleLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1)).cgPath

        // Arms
        func linePath(from: CGPoint, to: CGPoint) -> CGPath {
            let p = UIBezierPath(); p.move(to: from); p.addLine(to: to); return p.cgPath
        }
        hLeftLayer.path   = linePath(from: CGPoint(x: cx - gap - arm, y: cy), to: CGPoint(x: cx - gap, y: cy))
        hRightLayer.path  = linePath(from: CGPoint(x: cx + gap, y: cy),       to: CGPoint(x: cx + gap + arm, y: cy))
        vTopLayer.path    = linePath(from: CGPoint(x: cx, y: cy - gap - arm), to: CGPoint(x: cx, y: cy - gap))
        vBottomLayer.path = linePath(from: CGPoint(x: cx, y: cy + gap),       to: CGPoint(x: cx, y: cy + gap + arm))

        // Center dot
        let d: CGFloat = 5
        dotLayer.path = UIBezierPath(ovalIn: CGRect(x: cx - d/2, y: cy - d/2, width: d, height: d)).cgPath
    }
}
