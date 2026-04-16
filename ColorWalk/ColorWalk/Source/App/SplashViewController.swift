//
//  SplashViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit

final class SplashViewController: BaseViewController {

    // MARK: - Constants

    private enum Constants {
        static let tileSize: CGFloat = 72
        static let resolveScale: CGFloat = 1.0

        static let gatherStartDelay: TimeInterval = 0.3
        static let gatherDuration: TimeInterval = 0.85
        static let gatherStagger: TimeInterval = 0.04
        static let resolveStartDelay: TimeInterval = 1.5
        static let resolveDuration: TimeInterval = 0.6
        static let resolveStagger: TimeInterval = 0.04
        static let floatStartDelay: TimeInterval = 2.6
        static let floatDuration: TimeInterval = 2.4
        static let floatAmplitude: CGFloat = 5
        static let completionDelay: TimeInterval = 3.8
    }

    // MARK: - Tile Configuration

    private struct TileConfig {
        let imageName: String
        let scatterRelativeCenter: CGPoint
        let gatherRelativeCenter: CGPoint
        let resolveRelativeCenter: CGPoint
        let scatterRotation: CGFloat
        let gatherRotation: CGFloat
    }

    // 3×3 grid: tileSize=72, gap=6 → spacing=78pt
    // Grid center: (0.500, 0.450), columns: 0.292 / 0.500 / 0.708
    // Rows: 0.333 / 0.450 / 0.567
    private static let tileConfigs: [TileConfig] = [
        TileConfig(
            imageName: "orange",
            scatterRelativeCenter: CGPoint(x:  0.076, y:  0.117),
            gatherRelativeCenter:  CGPoint(x:  0.184, y:  0.225),
            resolveRelativeCenter: CGPoint(x:  0.292, y:  0.333),
            scatterRotation: -18 * .pi / 180,
            gatherRotation:  -12 * .pi / 180
        ),
        TileConfig(
            imageName: "yellow",
            scatterRelativeCenter: CGPoint(x:  0.499, y: -0.035),
            gatherRelativeCenter:  CGPoint(x:  0.500, y:  0.149),
            resolveRelativeCenter: CGPoint(x:  0.500, y:  0.333),
            scatterRotation:  12 * .pi / 180,
            gatherRotation:    8 * .pi / 180
        ),
        TileConfig(
            imageName: "pink",
            scatterRelativeCenter: CGPoint(x:  0.916, y:  0.094),
            gatherRelativeCenter:  CGPoint(x:  0.812, y:  0.214),
            resolveRelativeCenter: CGPoint(x:  0.708, y:  0.333),
            scatterRotation:  22 * .pi / 180,
            gatherRotation:   11 * .pi / 180
        ),
        TileConfig(
            imageName: "light_blue",
            scatterRelativeCenter: CGPoint(x: -0.025, y:  0.434),
            gatherRelativeCenter:  CGPoint(x:  0.134, y:  0.442),
            resolveRelativeCenter: CGPoint(x:  0.292, y:  0.450),
            scatterRotation: -25 * .pi / 180,
            gatherRotation:  -16 * .pi / 180
        ),
        TileConfig(
            imageName: "teal",
            scatterRelativeCenter: CGPoint(x:  0.503, y:  0.237),
            gatherRelativeCenter:  CGPoint(x:  0.500, y:  0.344),
            resolveRelativeCenter: CGPoint(x:  0.500, y:  0.450),
            scatterRotation:   8 * .pi / 180,
            gatherRotation:    4 * .pi / 180
        ),
        TileConfig(
            imageName: "purple",
            scatterRelativeCenter: CGPoint(x:  1.017, y:  0.423),
            gatherRelativeCenter:  CGPoint(x:  0.862, y:  0.437),
            resolveRelativeCenter: CGPoint(x:  0.708, y:  0.450),
            scatterRotation:  18 * .pi / 180,
            gatherRotation:   10 * .pi / 180
        ),
        TileConfig(
            imageName: "lime",
            scatterRelativeCenter: CGPoint(x:  0.076, y:  0.847),
            gatherRelativeCenter:  CGPoint(x:  0.184, y:  0.707),
            resolveRelativeCenter: CGPoint(x:  0.292, y:  0.567),
            scatterRotation: -15 * .pi / 180,
            gatherRotation:  -10 * .pi / 180
        ),
        TileConfig(
            imageName: "brown",
            scatterRelativeCenter: CGPoint(x:  0.499, y:  0.986),
            gatherRelativeCenter:  CGPoint(x:  0.500, y:  0.777),
            resolveRelativeCenter: CGPoint(x:  0.500, y:  0.567),
            scatterRotation:  -8 * .pi / 180,
            gatherRotation:   -5 * .pi / 180
        ),
        TileConfig(
            imageName: "navy",
            scatterRelativeCenter: CGPoint(x:  0.941, y:  0.883),
            gatherRelativeCenter:  CGPoint(x:  0.825, y:  0.725),
            resolveRelativeCenter: CGPoint(x:  0.708, y:  0.567),
            scatterRotation:  14 * .pi / 180,
            gatherRotation:    8 * .pi / 180
        ),
    ]

    // MARK: - Views

    private let backgroundGradientLayer = CAGradientLayer()
    private var tileViews: [UIView] = []

    // MARK: - Properties

    var onAnimationComplete: (() -> Void)?
    private var hasStartedAnimation = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        view.backgroundColor = UIColor(hex: "#FFFDFB")
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        if !hasStartedAnimation {
            positionTilesAtStart()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStartedAnimation else { return }
        hasStartedAnimation = true
        startAnimation()
    }

    // MARK: - Setup

    override func setupViews() {
        setupBackground()
        setupTiles()
    }

    override func setupConstraints() {}

    private func setupBackground() {
        backgroundGradientLayer.type = .radial
        backgroundGradientLayer.colors = [
            UIColor(hex: "#FFFDFB").cgColor,
            UIColor(hex: "#F6F2FA").cgColor,
            UIColor(hex: "#EDE7F6").cgColor
        ]
        backgroundGradientLayer.locations = [0, 0.62, 1]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.22)
        backgroundGradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
    }

    private func setupTiles() {
        for config in Self.tileConfigs {
            let tile = makeTileView(imageName: config.imageName, size: Constants.tileSize)
            view.addSubview(tile)
            tileViews.append(tile)
        }
    }

    // MARK: - Tile Positioning

    private func positionTilesAtStart() {
        let size = view.bounds.size
        for (index, tile) in tileViews.enumerated() {
            let config = Self.tileConfigs[index]
            tile.center = CGPoint(
                x: config.scatterRelativeCenter.x * size.width,
                y: config.scatterRelativeCenter.y * size.height
            )
            tile.transform = CGAffineTransform(rotationAngle: config.scatterRotation)
            tile.alpha = 0.85
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        let size = view.bounds.size
        let completion = onAnimationComplete

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.gatherStartDelay) { [weak self] in
            self?.animateGather(screenSize: size)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.resolveStartDelay) { [weak self] in
            self?.animateResolve(screenSize: size)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.floatStartDelay) { [weak self] in
            self?.startFloatingAnimation()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.completionDelay) {
            completion?()
        }
    }

    private func animateGather(screenSize: CGSize) {
        for (index, tile) in tileViews.enumerated() {
            let config = Self.tileConfigs[index]
            let target = CGPoint(
                x: config.gatherRelativeCenter.x * screenSize.width,
                y: config.gatherRelativeCenter.y * screenSize.height
            )
            UIView.animate(
                withDuration: Constants.gatherDuration,
                delay: Double(index) * Constants.gatherStagger,
                usingSpringWithDamping: 0.62,
                initialSpringVelocity: 0.6,
                options: []
            ) {
                tile.center = target
                tile.transform = CGAffineTransform(rotationAngle: config.gatherRotation)
            }
        }
    }

    private func animateResolve(screenSize: CGSize) {
        for (index, tile) in tileViews.enumerated() {
            let config = Self.tileConfigs[index]
            let target = CGPoint(
                x: config.resolveRelativeCenter.x * screenSize.width,
                y: config.resolveRelativeCenter.y * screenSize.height
            )
            UIView.animate(
                withDuration: Constants.resolveDuration,
                delay: Double(index) * Constants.resolveStagger,
                usingSpringWithDamping: 0.58,
                initialSpringVelocity: 0.7,
                options: []
            ) {
                tile.center = target
                tile.transform = .identity
            }
        }
    }

    private func startFloatingAnimation() {
        for (index, tile) in tileViews.enumerated() {
            let delay = Double(index) * 0.06
            let animation = CABasicAnimation(keyPath: "position.y")
            animation.byValue = -Constants.floatAmplitude
            animation.duration = Constants.floatDuration
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.beginTime = CACurrentMediaTime() + delay
            tile.layer.add(animation, forKey: "float")
        }
    }

    // MARK: - Helper

    private func makeTileView(imageName: String, size: CGFloat) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        container.backgroundColor = .clear

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        imageView.image = UIImage(named: imageName)
        imageView.contentMode = .scaleAspectFit

        container.addSubview(imageView)
        return container
    }
}
