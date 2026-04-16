//
//  SplashViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit

final class SplashViewController: BaseViewController {

    // MARK: - Constants

    private enum Constants {
        static let tileSize: CGFloat = 60
        static let tileCenterSize: CGFloat = 64
        static let tileCornerRadius: CGFloat = 14
        static let tileCenterCornerRadius: CGFloat = 15

        static let resolveScale: CGFloat = 52.0 / 60.0
        static let resolveScaleCenter: CGFloat = 56.0 / 64.0

        static let shellSize: CGFloat = 228
        static let shellCornerRadius: CGFloat = 52

        static let flyInDuration: TimeInterval = 0.7
        static let flyInStagger: TimeInterval = 0.07
        static let gatherStartDelay: TimeInterval = 1.5
        static let gatherDuration: TimeInterval = 0.85
        static let gatherStagger: TimeInterval = 0.04
        static let resolveStartDelay: TimeInterval = 2.7
        static let resolveDuration: TimeInterval = 0.6
        static let resolveStagger: TimeInterval = 0.04
        static let brandStartDelay: TimeInterval = 3.7
        static let brandDuration: TimeInterval = 0.5
        static let completionDelay: TimeInterval = 4.5
    }

    // MARK: - Tile Configuration

    private struct TileConfig {
        let color: UIColor
        let isCenter: Bool
        let startRelativeCenter: CGPoint
        let scatterRelativeCenter: CGPoint
        let gatherRelativeCenter: CGPoint
        let resolveRelativeCenter: CGPoint
        let scatterRotation: CGFloat
        let gatherRotation: CGFloat
        let resolveRotation: CGFloat
    }

    private static let tileConfigs: [TileConfig] = [
        TileConfig(
            color: UIColor(hex: "#F39A49"), isCenter: false,
            startRelativeCenter:   CGPoint(x: -0.20,  y:  0.117),
            scatterRelativeCenter: CGPoint(x:  0.076, y:  0.117),
            gatherRelativeCenter:  CGPoint(x:  0.186, y:  0.180),
            resolveRelativeCenter: CGPoint(x:  0.328, y:  0.377),
            scatterRotation: -18 * .pi / 180,
            gatherRotation:  -12 * .pi / 180,
            resolveRotation:  -6 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#FFD85C"), isCenter: false,
            startRelativeCenter:   CGPoint(x:  0.499, y: -0.150),
            scatterRelativeCenter: CGPoint(x:  0.499, y: -0.035),
            gatherRelativeCenter:  CGPoint(x:  0.486, y:  0.123),
            resolveRelativeCenter: CGPoint(x:  0.501, y:  0.377),
            scatterRotation:  12 * .pi / 180,
            gatherRotation:    8 * .pi / 180,
            resolveRotation:   5 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#F27CA5"), isCenter: false,
            startRelativeCenter:   CGPoint(x:  1.20,  y:  0.094),
            scatterRelativeCenter: CGPoint(x:  0.916, y:  0.094),
            gatherRelativeCenter:  CGPoint(x:  0.812, y:  0.191),
            resolveRelativeCenter: CGPoint(x:  0.674, y:  0.377),
            scatterRotation:  22 * .pi / 180,
            gatherRotation:   11 * .pi / 180,
            resolveRotation:   7 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#A8D8FF"), isCenter: false,
            startRelativeCenter:   CGPoint(x: -0.20,  y:  0.434),
            scatterRelativeCenter: CGPoint(x: -0.025, y:  0.434),
            gatherRelativeCenter:  CGPoint(x:  0.130, y:  0.412),
            resolveRelativeCenter: CGPoint(x:  0.323, y:  0.456),
            scatterRotation: -25 * .pi / 180,
            gatherRotation:  -16 * .pi / 180,
            resolveRotation:  -7 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#5ECAC6"), isCenter: true,
            startRelativeCenter:   CGPoint(x:  0.503, y: -0.150),
            scatterRelativeCenter: CGPoint(x:  0.503, y:  0.237),
            gatherRelativeCenter:  CGPoint(x:  0.504, y:  0.326),
            resolveRelativeCenter: CGPoint(x:  0.501, y:  0.459),
            scatterRotation:   8 * .pi / 180,
            gatherRotation:    4 * .pi / 180,
            resolveRotation:   4 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#A879E8"), isCenter: false,
            startRelativeCenter:   CGPoint(x:  1.20,  y:  0.423),
            scatterRelativeCenter: CGPoint(x:  1.017, y:  0.423),
            gatherRelativeCenter:  CGPoint(x:  0.868, y:  0.400),
            resolveRelativeCenter: CGPoint(x:  0.679, y:  0.456),
            scatterRotation:  18 * .pi / 180,
            gatherRotation:   10 * .pi / 180,
            resolveRotation:   6 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#A9DB54"), isCenter: false,
            startRelativeCenter:   CGPoint(x: -0.20,  y:  0.847),
            scatterRelativeCenter: CGPoint(x:  0.076, y:  0.847),
            gatherRelativeCenter:  CGPoint(x:  0.201, y:  0.696),
            resolveRelativeCenter: CGPoint(x:  0.328, y:  0.541),
            scatterRotation: -15 * .pi / 180,
            gatherRotation:  -10 * .pi / 180,
            resolveRotation:  -5 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#A77149"), isCenter: false,
            startRelativeCenter:   CGPoint(x:  0.499, y:  1.150),
            scatterRelativeCenter: CGPoint(x:  0.499, y:  0.986),
            gatherRelativeCenter:  CGPoint(x:  0.496, y:  0.774),
            resolveRelativeCenter: CGPoint(x:  0.501, y:  0.541),
            scatterRotation:  -8 * .pi / 180,
            gatherRotation:   -5 * .pi / 180,
            resolveRotation:  -3 * .pi / 180
        ),
        TileConfig(
            color: UIColor(hex: "#2D4277"), isCenter: false,
            startRelativeCenter:   CGPoint(x:  1.20,  y:  0.883),
            scatterRelativeCenter: CGPoint(x:  0.941, y:  0.883),
            gatherRelativeCenter:  CGPoint(x:  0.812, y:  0.703),
            resolveRelativeCenter: CGPoint(x:  0.674, y:  0.541),
            scatterRotation:  14 * .pi / 180,
            gatherRotation:    8 * .pi / 180,
            resolveRotation:   5 * .pi / 180
        ),
    ]

    // MARK: - Views

    private let backgroundGradientLayer = CAGradientLayer()
    private var tileViews: [UIView] = []
    private let iconShellView = UIView()
    private let brandStackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStartedAnimation else { return }
        hasStartedAnimation = true
        positionTilesAtStart()
        startAnimation()
    }

    // MARK: - Setup

    override func setupViews() {
        setupBackground()
        setupTiles()
        setupIconShell()
        setupBrand()
    }

    override func setupConstraints() {
        iconShellView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(Constants.shellSize)
            make.centerY.equalToSuperview().multipliedBy(0.918)
        }

        brandStackView.snp.makeConstraints { make in
            make.top.equalTo(iconShellView.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(28)
            make.trailing.lessThanOrEqualToSuperview().inset(28)
        }
    }

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
            let size = config.isCenter ? Constants.tileCenterSize : Constants.tileSize
            let radius = config.isCenter ? Constants.tileCenterCornerRadius : Constants.tileCornerRadius
            let tile = makeTileView(color: config.color, size: size, cornerRadius: radius)
            tile.alpha = 0
            view.addSubview(tile)
            tileViews.append(tile)
        }
    }

    private func setupIconShell() {
        iconShellView.backgroundColor = .clear
        iconShellView.clipsToBounds = false
        iconShellView.alpha = 0
        iconShellView.layer.shadowColor = UIColor(hex: "#D8CCE9").cgColor
        iconShellView.layer.shadowOpacity = 0.20
        iconShellView.layer.shadowOffset = CGSize(width: 0, height: 18)
        iconShellView.layer.shadowRadius = 24
        iconShellView.layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(origin: .zero, size: CGSize(width: Constants.shellSize, height: Constants.shellSize)),
            cornerRadius: Constants.shellCornerRadius
        ).cgPath

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blurView.layer.cornerRadius = Constants.shellCornerRadius
        blurView.clipsToBounds = true
        blurView.layer.borderWidth = 1
        blurView.layer.borderColor = UIColor(hex: "#E9E4EF").cgColor

        let whiteOverlay = UIView()
        whiteOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.80)
        whiteOverlay.isUserInteractionEnabled = false
        blurView.contentView.addSubview(whiteOverlay)
        whiteOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconShellView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(iconShellView)
    }

    private func setupBrand() {
        brandStackView.axis = .vertical
        brandStackView.alignment = .center
        brandStackView.spacing = 10
        brandStackView.alpha = 0
        brandStackView.transform = CGAffineTransform(translationX: 0, y: 12)

        titleLabel.text = "담아,"
        titleLabel.font = UIFont(name: "Pretendard-SemiBold", size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "#2A2233")
        titleLabel.textAlignment = .center

        subtitleLabel.text = "당신만의 색으로 가득 채워보세요"
        subtitleLabel.font = UIFont(name: "Pretendard-Regular", size: 15) ?? UIFont.systemFont(ofSize: 15)
        subtitleLabel.textColor = UIColor(hex: "#6F677C")
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        brandStackView.addArrangedSubview(titleLabel)
        brandStackView.addArrangedSubview(subtitleLabel)
        view.addSubview(brandStackView)
    }

    // MARK: - Tile Positioning

    private func positionTilesAtStart() {
        let size = view.bounds.size
        for (index, tile) in tileViews.enumerated() {
            let config = Self.tileConfigs[index]
            tile.center = CGPoint(
                x: config.startRelativeCenter.x * size.width,
                y: config.startRelativeCenter.y * size.height
            )
            tile.transform = CGAffineTransform(rotationAngle: config.scatterRotation)
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        let size = view.bounds.size
        let completion = onAnimationComplete

        for (index, tile) in tileViews.enumerated() {
            let config = Self.tileConfigs[index]
            let target = CGPoint(
                x: config.scatterRelativeCenter.x * size.width,
                y: config.scatterRelativeCenter.y * size.height
            )
            UIView.animate(
                withDuration: Constants.flyInDuration,
                delay: Double(index) * Constants.flyInStagger,
                usingSpringWithDamping: 0.72,
                initialSpringVelocity: 0.5,
                options: []
            ) {
                tile.alpha = 0.85
                tile.center = target
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.gatherStartDelay) { [weak self] in
            self?.animateGather(screenSize: size)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.resolveStartDelay) { [weak self] in
            self?.animateResolve(screenSize: size)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.brandStartDelay) { [weak self] in
            self?.animateBrand()
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
                usingSpringWithDamping: 0.80,
                initialSpringVelocity: 0.3,
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
            let scale = config.isCenter ? Constants.resolveScaleCenter : Constants.resolveScale
            UIView.animate(
                withDuration: Constants.resolveDuration,
                delay: Double(index) * Constants.resolveStagger,
                usingSpringWithDamping: 0.70,
                initialSpringVelocity: 0.5,
                options: []
            ) {
                tile.center = target
                tile.transform = CGAffineTransform(rotationAngle: config.resolveRotation)
                    .scaledBy(x: scale, y: scale)
            }
        }
    }

    private func animateBrand() {
        UIView.animate(
            withDuration: Constants.brandDuration,
            delay: 0,
            options: [.curveEaseOut]
        ) { [weak self] in
            self?.iconShellView.alpha = 1
        }

        UIView.animate(
            withDuration: Constants.brandDuration,
            delay: 0.15,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: []
        ) { [weak self] in
            self?.brandStackView.alpha = 1
            self?.brandStackView.transform = .identity
        }
    }

    // MARK: - Helper

    private func makeTileView(color: UIColor, size: CGFloat, cornerRadius: CGFloat) -> UIView {
        let shadowContainer = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        shadowContainer.backgroundColor = .clear
        shadowContainer.layer.shadowColor = color.cgColor
        shadowContainer.layer.shadowOpacity = 0.25
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 10)
        shadowContainer.layer.shadowRadius = 9
        shadowContainer.layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
            cornerRadius: cornerRadius
        ).cgPath

        let inner = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        inner.backgroundColor = color
        inner.layer.cornerRadius = cornerRadius
        inner.clipsToBounds = true

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.33).cgColor,
            UIColor.black.withAlphaComponent(0.13).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        inner.layer.addSublayer(gradientLayer)

        shadowContainer.addSubview(inner)
        return shadowContainer
    }
}
