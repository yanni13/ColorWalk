//
//  ColorDetailViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift
import RxCocoa

final class ColorDetailViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ColorDetailViewModel
    private let swipeLeftSubject  = PublishSubject<Void>()
    private let swipeRightSubject = PublishSubject<Void>()

    // MARK: - UI: Background
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let gradientOverlayView = UIView()
    private let gradientLayer = CAGradientLayer()

    // MARK: - UI: Top Controls
    private let backButton = DetailGlassButton(icon: "chevron.left")
    private let shareButton = DetailGlassButton(icon: "square.and.arrow.up")

    private let pageCounterView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        return v
    }()
    private let pageCounterBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        return v
    }()
    private let pageCounterDim: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.082)
        return v
    }()
    private let pageCounterLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Medium", size: 12)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    // MARK: - UI: Bottom Info
    private let colorDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        return v
    }()

    private let colorNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 32)
        l.textColor = .white
        return l
    }()

    private lazy var colorNameRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [colorDotView, colorNameLabel])
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        return s
    }()

    private let hexCodeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 16)
        l.textColor = UIColor.white.withAlphaComponent(0.5)
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 12)
        l.textColor = UIColor.white.withAlphaComponent(0.4)
        return l
    }()

    // MARK: - UI: Swipe Hint
    private let swipeChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        iv.tintColor = .white
        iv.alpha = 0.3
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - Init

    init(viewModel: ColorDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = gradientOverlayView.bounds
    }

    // MARK: - setupViews

    override func setupViews() {
        view.backgroundColor = .black

        // Gradient setup (f9RNW: transparent → #000000DD, top→bottom)
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor(white: 0, alpha: 0.733).cgColor,  // #000000BB
            UIColor(white: 0, alpha: 0.867).cgColor   // #000000DD
        ]
        gradientLayer.locations = [0, 0.4, 0.75, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        gradientOverlayView.layer.addSublayer(gradientLayer)

        // Counter blur layers
        pageCounterView.addSubview(pageCounterBlur)
        pageCounterView.addSubview(pageCounterDim)
        pageCounterView.addSubview(pageCounterLabel)

        [backgroundImageView, gradientOverlayView,
         backButton, shareButton, pageCounterView,
         colorNameRow, hexCodeLabel, metaLabel,
         swipeChevron].forEach { view.addSubview($0) }

        setupGesture()
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        backgroundImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        gradientOverlayView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Top controls — y:58 in 852pt design
        backButton.snp.makeConstraints {
            $0.width.height.equalTo(44)
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
        }
        shareButton.snp.makeConstraints {
            $0.width.height.equalTo(44)
            $0.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
        }
        pageCounterView.snp.makeConstraints {
            $0.width.equalTo(66)
            $0.height.equalTo(28)
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(backButton)
        }
        pageCounterBlur.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageCounterDim.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageCounterLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Bottom info — positions from f9RNW (852pt screen)
        colorNameRow.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.bottom.equalToSuperview().inset(182)  // 852 - 670 = 182
        }
        colorDotView.snp.makeConstraints { $0.width.height.equalTo(16) }

        hexCodeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(colorNameRow.snp.bottom).offset(4)
        }
        metaLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(hexCodeLabel.snp.bottom).offset(8)
        }

        // Swipe hint chevron — right edge, vertically centered
        swipeChevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
    }

    // MARK: - bind

    override func bind() {
        let input = ColorDetailViewModel.Input(
            swipeLeft:  swipeLeftSubject.asObservable(),
            swipeRight: swipeRightSubject.asObservable(),
            backTap:    backButton.rx.tap.asObservable(),
            shareTap:   shareButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.currentCard
            .drive(onNext: { [weak self] card in self?.configure(card: card) })
            .disposed(by: disposeBag)

        output.pageText
            .drive(pageCounterLabel.rx.text)
            .disposed(by: disposeBag)
    }

    // MARK: - Gesture

    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let translation = gesture.translation(in: view)
        let velocity    = gesture.velocity(in: view)

        if translation.x < -60 || velocity.x < -400 {
            swipeLeftSubject.onNext(())
        } else if translation.x > 60 || velocity.x > 400 {
            swipeRightSubject.onNext(())
        }
    }

    // MARK: - Configure

    private func configure(card: ColorCard) {
        // 이미지 크로스페이드
        if let url = card.imageURL {
            backgroundImageView.kf.setImage(with: url, options: [.transition(.fade(0.25))])
        }

        colorDotView.backgroundColor = card.dotColor

        let nameAttr = NSMutableAttributedString(string: card.colorName)
        nameAttr.addAttribute(.kern, value: -0.5, range: NSRange(location: 0, length: card.colorName.count))
        colorNameLabel.attributedText = nameAttr

        hexCodeLabel.text = card.hexColor
        metaLabel.text    = "\(card.captureDate) · \(card.locationName)"
    }
}

// MARK: - DetailGlassButton

private final class DetailGlassButton: UIButton {

    init(icon: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 22
        clipsToBounds = true

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        let dimView = UIView()
        dimView.backgroundColor = UIColor.white.withAlphaComponent(0.082)  // #FFFFFF15

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false

        [blurView, dimView, iconView].forEach { addSubview($0) }

        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        dimView.snp.makeConstraints  { $0.edges.equalToSuperview() }
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(22) }
    }

    required init?(coder: NSCoder) { fatalError() }
}
