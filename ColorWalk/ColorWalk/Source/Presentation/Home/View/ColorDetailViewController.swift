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

    private let gradientOverlayView = GradientView(
        colors: [
            .clear,
            .clear,
            UIColor(white: 0, alpha: 0.733),
            UIColor(white: 0, alpha: 0.867)
        ],
        locations: [0, 0.4, 0.75, 1.0]
    )

    // MARK: - UI: Top Controls
    private let backButton  = GlassPillButton(icon: "chevron.left")
    private let shareButton = GlassPillButton(icon: "square.and.arrow.up")

    private let pageCounterView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        return v
    }()
    private let pageCounterGlass = GlassView(dimStyle: .light, cornerRadius: 14)
    private let pageCounterLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Medium", size: 12)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    // MARK: - UI: Bottom Info
    private let colorDotView = ColorDotView(size: 16, borderColor: .white, borderWidth: 2)

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

    // MARK: - setupViews

    override func setupViews() {
        view.backgroundColor = .black

        pageCounterView.addSubview(pageCounterGlass)
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

        // Top controls
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
        pageCounterGlass.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageCounterLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Bottom info
        colorNameRow.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.bottom.equalToSuperview().inset(182)
        }

        hexCodeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(colorNameRow.snp.bottom).offset(4)
        }
        metaLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(hexCodeLabel.snp.bottom).offset(8)
        }

        // Swipe hint chevron
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
        if let img = card.capturedImage {
            backgroundImageView.image = img
        } else if let url = card.imageURL {
            backgroundImageView.kf.setImage(with: url, options: [.transition(.fade(0.25))])
        }

        colorDotView.setColor(card.dotColor)

        let nameAttr = NSMutableAttributedString(string: card.colorName)
        nameAttr.addAttribute(.kern, value: -0.5, range: NSRange(location: 0, length: card.colorName.count))
        colorNameLabel.attributedText = nameAttr

        hexCodeLabel.text = card.hexColor
        metaLabel.text = "\(card.captureDate) · \(card.locationName)"
    }
}
