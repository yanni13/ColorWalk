
//
//  SpectrumHueViews.swift
//  ColorWalk
//

import UIKit

// MARK: - SpectrumView

final class SpectrumView: UIView {

    var hue: CGFloat = 0 { didSet { updateHueColor() } }
    var onColorChanged: ((CGFloat, CGFloat) -> Void)? // (saturation, brightness)

    private let saturationLayer = CAGradientLayer()
    private let brightnessLayer = CAGradientLayer()
    private let selectorView = UIView()
    private var normalizedPosition = CGPoint(x: 0.5, y: 0.5)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupSelector()
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        saturationLayer.frame = bounds
        brightnessLayer.frame = bounds
        updateSelectorFrame()
    }

    // MARK: - Setup

    private func setupLayers() {
        layer.cornerRadius = 12
        layer.masksToBounds = true

        saturationLayer.startPoint = CGPoint(x: 0, y: 0.5)
        saturationLayer.endPoint = CGPoint(x: 1, y: 0.5)
        updateHueColor()
        layer.addSublayer(saturationLayer)

        brightnessLayer.startPoint = CGPoint(x: 0.5, y: 0)
        brightnessLayer.endPoint = CGPoint(x: 0.5, y: 1)
        brightnessLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        layer.addSublayer(brightnessLayer)
    }

    private func setupSelector() {
        selectorView.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        selectorView.layer.cornerRadius = 11
        selectorView.layer.borderWidth = 3
        selectorView.layer.borderColor = UIColor.white.cgColor
        selectorView.layer.shadowColor = UIColor.black.cgColor
        selectorView.layer.shadowOffset = CGSize(width: 0, height: 1)
        selectorView.layer.shadowRadius = 4
        selectorView.layer.shadowOpacity = 0.25
        selectorView.isUserInteractionEnabled = false
        addSubview(selectorView)
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(pan)
        addGestureRecognizer(tap)
    }

    // MARK: - Update

    private func updateHueColor() {
        let hueColor = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
        saturationLayer.colors = [UIColor.white.cgColor, hueColor.cgColor]
    }

    private func updateSelectorFrame() {
        let x = normalizedPosition.x * bounds.width - 11
        let y = normalizedPosition.y * bounds.height - 11
        selectorView.frame = CGRect(x: x, y: y, width: 22, height: 22)
    }

    @objc private func handleGesture(_ g: UIGestureRecognizer) {
        let loc = g.location(in: self)
        normalizedPosition = CGPoint(
            x: max(0, min(1, loc.x / max(1, bounds.width))),
            y: max(0, min(1, loc.y / max(1, bounds.height)))
        )
        updateSelectorFrame()
        onColorChanged?(normalizedPosition.x, 1 - normalizedPosition.y)
    }
}

// MARK: - HueBarView

final class HueBarView: UIView {

    var onHueChanged: ((CGFloat) -> Void)?

    private let rainbowLayer = CAGradientLayer()
    private let thumbView = UIView()
    private var hue: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
        setupThumb()
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        rainbowLayer.frame = bounds
        updateThumbFrame()
    }

    private func setupLayer() {
        layer.cornerRadius = 12
        layer.masksToBounds = true

        rainbowLayer.startPoint = CGPoint(x: 0, y: 0.5)
        rainbowLayer.endPoint = CGPoint(x: 1, y: 0.5)
        rainbowLayer.cornerRadius = 12
        rainbowLayer.colors = [0.0, 0.1, 0.167, 0.333, 0.5, 0.667, 0.833, 1.0].map {
            UIColor(hue: $0, saturation: 1, brightness: 1, alpha: 1).cgColor
        }
        rainbowLayer.locations = [0, 0.1, 0.167, 0.333, 0.5, 0.667, 0.833, 1.0]
        layer.addSublayer(rainbowLayer)
    }

    private func setupThumb() {
        thumbView.layer.cornerRadius = 12
        thumbView.layer.borderWidth = 3
        thumbView.layer.borderColor = UIColor.white.cgColor
        thumbView.layer.shadowColor = UIColor.black.cgColor
        thumbView.layer.shadowOffset = CGSize(width: 0, height: 1)
        thumbView.layer.shadowRadius = 4
        thumbView.layer.shadowOpacity = 0.2
        thumbView.isUserInteractionEnabled = false
        addSubview(thumbView)
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(pan)
        addGestureRecognizer(tap)
    }

    private func updateThumbFrame() {
        let x = hue * bounds.width
        thumbView.frame = CGRect(x: x - 12, y: 0, width: 24, height: 24)
        thumbView.backgroundColor = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
    }

    @objc private func handleGesture(_ g: UIGestureRecognizer) {
        let loc = g.location(in: self)
        hue = max(0, min(0.9999, loc.x / max(1, bounds.width)))
        updateThumbFrame()
        onHueChanged?(hue)
    }
}
