//
//  ColorDetailViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift
import RxCocoa
import LinkPresentation
import Photos
import CoreLocation
import Vision

final class ColorDetailViewController: BaseViewController {

    // MARK: - Constants

    private enum Constants {
        static let controlSize: CGFloat = 44
        static let controlTopOffset: CGFloat = 10
        static let controlHorizontalInset: CGFloat = 20
        static let pageCounterWidth: CGFloat = 66
        static let pageCounterHeight: CGFloat = 28
        static let colorNameBottomInset: CGFloat = 182
        static let colorNameLeading: CGFloat = 24
        static let swipeHorizontalThreshold: CGFloat = 60
        static let swipeHorizontalVelocity: CGFloat = 400
        static let swipeVerticalThreshold: CGFloat = 60
        static let swipeVerticalVelocity: CGFloat = 400
        static let tipDelay: TimeInterval = 1.5
        static let tipAutoDismissDelay: TimeInterval = 4.0
        static let sparkleFadeDuration: TimeInterval = 2.0
        static let tipWidth: CGFloat = 280
        static let sparkleBadgeSize: CGFloat = 28
        static let toastWidth: CGFloat = 320
        static let onboardingKey = "colorDetail_stickerOnboardingCompleted"
        static let accentPink = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0)
        static let accentGreen = UIColor(red: 0.204, green: 0.827, blue: 0.600, alpha: 1.0)
    }

    // MARK: - Properties

    private let viewModel: ColorDetailViewModel
    private let swipeLeftSubject  = PublishSubject<Void>()
    private let swipeRightSubject = PublishSubject<Void>()
    private var isInfoVisible: Bool = true
    private var contextualTipTimer: Timer?
    private var isExtracting = false
    private var currentCard: ColorCard?

    private enum SwipeDirection { case left, right, none }
    private var pendingSwipeDirection: SwipeDirection = .none

    private var isOnboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.onboardingKey) }
    }

    // MARK: - UI: Background

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
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

    // MARK: - UI: Subject Extraction

    private let subjectGlowView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        v.layer.borderWidth = 1
        v.layer.cornerRadius = 110
        v.layer.shadowColor = UIColor.white.cgColor
        v.layer.shadowRadius = 24
        v.layer.shadowOpacity = 0.25
        v.layer.shadowOffset = .zero
        v.alpha = 0
        v.isUserInteractionEnabled = false
        return v
    }()

    private let touchRippleView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderColor = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 0.85).cgColor
        v.layer.borderWidth = 2
        v.layer.cornerRadius = 30
        v.layer.shadowColor = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0).cgColor
        v.layer.shadowRadius = 8
        v.layer.shadowOpacity = 0.6
        v.layer.shadowOffset = .zero
        v.alpha = 0
        v.isUserInteractionEnabled = false
        return v
    }()

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

    // MARK: - UI: Swipe Hint Chevrons

    private let swipeLeftChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let swipeRightChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.alpha = 0
        iv.isUserInteractionEnabled = true
        return iv
    }()

    // MARK: - UI: Layer 1 — Swipe Up Indicator

    private let swipeUpIndicatorView: UIView = {
        let v = UIView()
        v.alpha = 0
        v.isUserInteractionEnabled = false
        return v
    }()

    private let swipeUpChevronView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.up")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        iv.tintColor = UIColor.white.withAlphaComponent(0.4)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let swipeUpHintLabel: UILabel = {
        let l = UILabel()
        l.text = "위로 스와이프하여 정보 보기"
        l.font = UIFont(name: "Pretendard-Regular", size: 10)
        l.textColor = UIColor.white.withAlphaComponent(0.3)
        l.textAlignment = .center
        return l
    }()

    // MARK: - UI: Layer 2 — Contextual Tip

    private let dimOverlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.145)
        v.alpha = 0
        v.isUserInteractionEnabled = false
        return v
    }()

    private let tipContainerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.alpha = 0
        v.isHidden = true
        return v
    }()

    private let tipBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))

    private let tipTintView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 0.941)
        return v
    }()

    private let tipIconContainerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.clipsToBounds = true
        return v
    }()

    private let tipIconGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.373, blue: 0.635, alpha: 1.0).cgColor
        ]
        l.startPoint = CGPoint(x: 0.5, y: 0)
        l.endPoint   = CGPoint(x: 0.5, y: 1)
        return l
    }()

    private let tipIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "sparkles")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let tipTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "스티커 만들기"
        l.font = UIFont(name: "Pretendard-SemiBold", size: 15)
        l.textColor = .white
        return l
    }()

    private let tipSubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "새로운 기능"
        l.font = UIFont(name: "Pretendard-Medium", size: 11)
        l.textColor = UIColor.white.withAlphaComponent(0.314)
        return l
    }()

    private let tipCloseButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .medium)
        b.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        b.tintColor = UIColor.white.withAlphaComponent(0.4)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.125)
        b.layer.cornerRadius = 12
        b.clipsToBounds = true
        b.accessibilityLabel = "팁 닫기"
        return b
    }()

    private let tipBodyLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.45
        l.attributedText = NSAttributedString(
            string: "사진을 꾹 눌러 피사체를 분리하고\n스티커로 만들어보세요",
            attributes: [
                .font: UIFont(name: "Pretendard-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.white.withAlphaComponent(0.733),
                .paragraphStyle: paragraph
            ]
        )
        return l
    }()

    private let longPressRingView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderColor = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0).cgColor
        v.layer.borderWidth = 2
        v.layer.cornerRadius = 16
        return v
    }()

    private let longPressDotView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0)
        v.layer.cornerRadius = 6
        return v
    }()

    private let gestureIconContainerView = UIView()

    private let gestureHintLabel: UILabel = {
        let l = UILabel()
        l.attributedText = NSAttributedString(
            string: "길게 누르기",
            attributes: [
                .font: UIFont(name: "Pretendard-SemiBold", size: 12) ?? UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0),
                .kern: 0.5
            ]
        )
        return l
    }()

    private lazy var gestureRowStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [gestureIconContainerView, gestureHintLabel])
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private let tipArrowView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 0.941)
        v.alpha = 0
        v.isHidden = true
        return v
    }()

    // MARK: - UI: Layer 3 — Sparkle Badge

    private let sparkleBadgeView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.clipsToBounds = true
        v.alpha = 0
        v.isUserInteractionEnabled = false
        return v
    }()

    private let sparkleBadgeBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    private let sparkleBadgeTintView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 0.267)
        return v
    }()

    private let sparkleBadgeIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "sparkles")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - UI: Layer 4 — Status Pill

    private let statusPillView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        v.alpha = 0
        return v
    }()

    private let statusPillBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    private let statusPillTintView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.733)
        return v
    }()

    private let statusPillDotView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0)
        v.layer.cornerRadius = 3
        v.layer.shadowColor = UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0).cgColor
        v.layer.shadowRadius = 4
        v.layer.shadowOpacity = 1.0
        v.layer.shadowOffset = .zero
        return v
    }()

    private let statusPillLabel: UILabel = {
        let l = UILabel()
        l.text = "피사체 분리 중"
        l.font = UIFont(name: "Pretendard-Medium", size: 12)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        return l
    }()

    private lazy var statusPillContentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [statusPillDotView, statusPillLabel])
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    // MARK: - UI: Layer 5 — Success Toast

    private let successToastView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.alpha = 0
        return v
    }()

    private let toastBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))

    private let toastTintView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 0.933)
        return v
    }()

    private let toastCheckContainerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let toastCheckGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.373, blue: 0.635, alpha: 1.0).cgColor
        ]
        l.startPoint = CGPoint(x: 0.5, y: 0)
        l.endPoint   = CGPoint(x: 0.5, y: 1)
        return l
    }()

    private let toastCheckIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let toastTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "스티커가 저장되었어요"
        l.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        l.textColor = .white
        return l
    }()

    private let toastSubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "스티커 보관함에서 확인하세요"
        l.font = UIFont(name: "Pretendard-Regular", size: 12)
        l.textColor = UIColor.white.withAlphaComponent(0.4)
        return l
    }()

    private let toastActionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("보기", for: .normal)
        b.setTitleColor(UIColor(red: 1.0, green: 0.494, blue: 0.702, alpha: 1.0), for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-SemiBold", size: 13)
        b.accessibilityLabel = "스티커 보관함 보기"
        return b
    }()

    private lazy var toastTextStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [toastTitleLabel, toastSubtitleLabel])
        s.axis = .vertical
        s.spacing = 2
        return s
    }()

    private lazy var toastContentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [toastCheckContainerView, toastTextStack, toastActionButton])
        s.axis = .horizontal
        s.spacing = 12
        s.alignment = .center
        return s
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        triggerOnboardingIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        contextualTipTimer?.invalidate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tipIconGradientLayer.frame    = tipIconContainerView.bounds
        toastCheckGradientLayer.frame = toastCheckContainerView.bounds
    }

    // MARK: - setupViews

    override func setupViews() {
        view.backgroundColor = .black

        pageCounterView.addSubview(pageCounterGlass)
        pageCounterView.addSubview(pageCounterLabel)

        // Layer 1
        swipeUpIndicatorView.addSubview(swipeUpChevronView)
        swipeUpIndicatorView.addSubview(swipeUpHintLabel)

        // Layer 2 — tip icon gradient
        tipIconContainerView.layer.addSublayer(tipIconGradientLayer)
        tipIconContainerView.addSubview(tipIconImageView)

        gestureIconContainerView.addSubview(longPressRingView)
        gestureIconContainerView.addSubview(longPressDotView)

        tipContainerView.addSubview(tipBlurView)
        tipContainerView.addSubview(tipTintView)
        tipContainerView.addSubview(tipIconContainerView)
        tipContainerView.addSubview(tipTitleLabel)
        tipContainerView.addSubview(tipSubtitleLabel)
        tipContainerView.addSubview(tipCloseButton)
        tipContainerView.addSubview(tipBodyLabel)
        tipContainerView.addSubview(gestureRowStack)

        // Layer 3
        sparkleBadgeView.addSubview(sparkleBadgeBlurView)
        sparkleBadgeView.addSubview(sparkleBadgeTintView)
        sparkleBadgeView.addSubview(sparkleBadgeIconView)

        // Layer 4
        statusPillView.addSubview(statusPillBlurView)
        statusPillView.addSubview(statusPillTintView)
        statusPillView.addSubview(statusPillContentStack)

        // Layer 5 — toast check gradient
        toastCheckContainerView.layer.addSublayer(toastCheckGradientLayer)
        toastCheckContainerView.addSubview(toastCheckIconView)

        successToastView.addSubview(toastBlurView)
        successToastView.addSubview(toastTintView)
        successToastView.addSubview(toastContentStack)

        [backgroundImageView, subjectGlowView, touchRippleView, gradientOverlayView,
         backButton, shareButton, pageCounterView,
         colorNameRow, hexCodeLabel, metaLabel,
         swipeLeftChevron, swipeRightChevron,
         swipeUpIndicatorView,
         dimOverlayView,
         tipArrowView, tipContainerView,
         sparkleBadgeView,
         statusPillView,
         successToastView
        ].forEach { view.addSubview($0) }

        setupGesture()
        setupChevronTaps()
        setupLongPressGesture()
        setupTipCloseButton()
        setupToastActionButton()
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        backgroundImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        gradientOverlayView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        subjectGlowView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(220)
            make.height.equalTo(260)
        }
        touchRippleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(60)
        }

        // Top controls
        backButton.snp.makeConstraints { make in
            make.width.height.equalTo(Constants.controlSize)
            make.leading.equalToSuperview().offset(Constants.controlHorizontalInset)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.controlTopOffset)
        }
        shareButton.snp.makeConstraints { make in
            make.width.height.equalTo(Constants.controlSize)
            make.trailing.equalToSuperview().inset(Constants.controlHorizontalInset)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.controlTopOffset)
        }
        pageCounterView.snp.makeConstraints { make in
            make.width.equalTo(Constants.pageCounterWidth)
            make.height.equalTo(Constants.pageCounterHeight)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
        pageCounterGlass.snp.makeConstraints { make in make.edges.equalToSuperview() }
        pageCounterLabel.snp.makeConstraints { make in make.edges.equalToSuperview() }

        // Bottom info
        colorNameRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.colorNameLeading)
            make.bottom.equalToSuperview().inset(Constants.colorNameBottomInset)
        }
        hexCodeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.colorNameLeading)
            make.top.equalTo(colorNameRow.snp.bottom).offset(4)
        }
        metaLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.colorNameLeading)
            make.top.equalTo(hexCodeLabel.snp.bottom).offset(8)
        }

        // Swipe hint chevrons
        swipeLeftChevron.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        swipeRightChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // Layer 1 — Swipe Up Indicator
        swipeUpIndicatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(60)
            make.height.equalTo(60)
        }
        swipeUpChevronView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(14)
        }
        swipeUpHintLabel.snp.makeConstraints { make in
            make.top.equalTo(swipeUpChevronView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        // Dim overlay
        dimOverlayView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        // Layer 2 — Contextual Tip
        tipArrowView.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(8)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(tipContainerView.snp.top)
        }
        tipContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(Constants.tipWidth)
            make.top.equalTo(view.snp.centerY).offset(114)
        }
        tipBlurView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        tipTintView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        tipIconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(34)
        }
        tipIconImageView.snp.makeConstraints { make in make.center.equalToSuperview() }

        tipTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(tipIconContainerView.snp.trailing).offset(10)
            make.top.equalTo(tipIconContainerView)
            make.trailing.equalTo(tipCloseButton.snp.leading).offset(-8)
        }
        tipSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(tipTitleLabel)
            make.top.equalTo(tipTitleLabel.snp.bottom).offset(2)
        }
        tipCloseButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(18)
            make.centerY.equalTo(tipIconContainerView)
            make.width.height.equalTo(24)
        }
        tipBodyLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().inset(18)
            make.top.equalTo(tipIconContainerView.snp.bottom).offset(12)
        }

        // Gesture row
        gestureRowStack.snp.makeConstraints { make in
            make.top.equalTo(tipBodyLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(16)
        }
        gestureIconContainerView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        longPressRingView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        longPressDotView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }

        // Layer 3 — Sparkle Badge
        sparkleBadgeView.snp.makeConstraints { make in
            make.trailing.equalTo(shareButton.snp.trailing).offset(6)
            make.top.equalTo(shareButton.snp.top).offset(-6)
            make.width.height.equalTo(Constants.sparkleBadgeSize)
        }
        sparkleBadgeBlurView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        sparkleBadgeTintView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        sparkleBadgeIconView.snp.makeConstraints { make in make.center.equalToSuperview() }

        // Layer 4 — Status Pill
        statusPillView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(view.snp.centerY).offset(114)
        }
        statusPillBlurView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        statusPillTintView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        statusPillContentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        statusPillDotView.snp.makeConstraints { make in make.width.height.equalTo(6) }

        // Layer 5 — Success Toast
        successToastView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(Constants.toastWidth)
            make.bottom.equalToSuperview().inset(102)
        }
        toastBlurView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        toastTintView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        toastContentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        toastCheckContainerView.snp.makeConstraints { make in make.width.height.equalTo(32) }
        toastCheckIconView.snp.makeConstraints { make in make.center.equalToSuperview() }
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

        output.shareCard
            .drive(onNext: { [weak self] card in self?.presentShareSheet(for: card) })
            .disposed(by: disposeBag)

        output.chevronState
            .drive(onNext: { [weak self] state in
                guard let self else { return }
                UIView.animate(withDuration: 0.2) {
                    self.swipeLeftChevron.alpha = state.leftAlpha
                    self.swipeRightChevron.alpha = state.rightAlpha
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Gesture Setup

    private func setupGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    private func setupChevronTaps() {
        let leftTap = UITapGestureRecognizer(target: self, action: #selector(handleLeftChevronTap))
        swipeLeftChevron.addGestureRecognizer(leftTap)

        let rightTap = UITapGestureRecognizer(target: self, action: #selector(handleRightChevronTap))
        swipeRightChevron.addGestureRecognizer(rightTap)
    }

    private func setupLongPressGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.8
        view.addGestureRecognizer(longPress)
    }

    private func setupTipCloseButton() {
        tipCloseButton.addTarget(self, action: #selector(handleTipCloseTap), for: .touchUpInside)
    }

    private func setupToastActionButton() {
        toastActionButton.addTarget(self, action: #selector(handleToastActionTap), for: .touchUpInside)
    }

    // MARK: - Gesture Handlers

    @objc private func handleLeftChevronTap() {
        pendingSwipeDirection = .right
        swipeRightSubject.onNext(())
    }

    @objc private func handleRightChevronTap() {
        pendingSwipeDirection = .left
        swipeLeftSubject.onNext(())
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let translation = gesture.translation(in: view)
        let velocity    = gesture.velocity(in: view)
        let isHorizontalDominant = abs(translation.x) > abs(translation.y)

        if isHorizontalDominant {
            if translation.x < -Constants.swipeHorizontalThreshold || velocity.x < -Constants.swipeHorizontalVelocity {
                pendingSwipeDirection = .left
                swipeLeftSubject.onNext(())
            } else if translation.x > Constants.swipeHorizontalThreshold || velocity.x > Constants.swipeHorizontalVelocity {
                pendingSwipeDirection = .right
                swipeRightSubject.onNext(())
            }
        } else {
            if translation.y > Constants.swipeVerticalThreshold || velocity.y > Constants.swipeVerticalVelocity {
                hideInfoOverlay()
            } else if translation.y < -Constants.swipeVerticalThreshold || velocity.y < -Constants.swipeVerticalVelocity {
                showInfoOverlay()
            }
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            let point = gesture.location(in: view)
            startVisionExtraction(at: point)
        case .cancelled, .failed:
            if isExtracting { break }
            cancelExtractionAnimation()
        default:
            break
        }
    }

    @objc private func handleTipCloseTap() {
        dismissTip(animated: true)
    }

    @objc private func handleToastActionTap() {
        UIView.animate(withDuration: 0.2) {
            self.successToastView.alpha = 0
        }
    }

    // MARK: - Overlay Helpers

    private func hideInfoOverlay() {
        guard isInfoVisible else { return }
        isInfoVisible = false
        UIView.animate(withDuration: 0.3) {
            self.colorNameRow.alpha = 0
            self.hexCodeLabel.alpha = 0
            self.metaLabel.alpha = 0
            self.gradientOverlayView.alpha = 0
            self.swipeUpIndicatorView.alpha = 1
        } completion: { [weak self] _ in
            self?.triggerOnboardingIfNeeded()
        }
    }

    private func showInfoOverlay() {
        guard !isInfoVisible else { return }
        isInfoVisible = true
        dismissTip(animated: true)
        UIView.animate(withDuration: 0.3) {
            self.colorNameRow.alpha = 1
            self.hexCodeLabel.alpha = 1
            self.metaLabel.alpha = 1
            self.gradientOverlayView.alpha = 1
            self.swipeUpIndicatorView.alpha = 0
        }
    }

    // MARK: - Onboarding Helpers

    private func triggerOnboardingIfNeeded() {
        guard !isInfoVisible else { return }
        if !isOnboardingCompleted {
            contextualTipTimer = Timer.scheduledTimer(withTimeInterval: Constants.tipDelay, repeats: false) { [weak self] _ in
                self?.showContextualTip()
            }
        } else {
            showSparkleBadge()
        }
    }

    private func showContextualTip() {
        tipContainerView.isHidden = false
        tipArrowView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.dimOverlayView.alpha = 1
            self.tipContainerView.alpha = 1
            self.tipArrowView.alpha = 1
        }
        contextualTipTimer = Timer.scheduledTimer(withTimeInterval: Constants.tipAutoDismissDelay, repeats: false) { [weak self] _ in
            self?.dismissTip(animated: true)
        }
    }

    private func dismissTip(animated: Bool) {
        contextualTipTimer?.invalidate()
        contextualTipTimer = nil
        guard tipContainerView.alpha > 0 else { return }
        let hide = {
            self.dimOverlayView.alpha = 0
            self.tipContainerView.alpha = 0
            self.tipArrowView.alpha = 0
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: hide) { [weak self] _ in
                self?.tipContainerView.isHidden = true
                self?.tipArrowView.isHidden = true
            }
        } else {
            hide()
            tipContainerView.isHidden = true
            tipArrowView.isHidden = true
        }
        isOnboardingCompleted = true
    }

    private func showSparkleBadge() {
        UIView.animate(withDuration: 0.5) {
            self.sparkleBadgeView.alpha = 1
        } completion: { [weak self] _ in
            UIView.animate(withDuration: Constants.sparkleFadeDuration) {
                self?.sparkleBadgeView.alpha = 0
            }
        }
    }

    // MARK: - Sticker Extraction

    private func startVisionExtraction(at point: CGPoint) {
        guard !isExtracting else { return }
        isExtracting = true

        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        touchRippleView.center = point

        UIView.animate(withDuration: 0.2) {
            self.backgroundImageView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.subjectGlowView.alpha = 1
            self.touchRippleView.alpha = 1
            self.statusPillView.alpha = 1
        }

        guard let image = backgroundImageView.image else {
            cancelExtractionAnimation()
            return
        }

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let extracted = try await self.extractSubject(from: image)
                await MainActor.run {
                    self.finishExtraction(with: extracted)
                }
            } catch {
                await MainActor.run {
                    self.cancelExtractionAnimation()
                }
            }
        }
    }

    private func cancelExtractionAnimation() {
        isExtracting = false
        UIView.animate(withDuration: 0.2) {
            self.backgroundImageView.transform = .identity
            self.subjectGlowView.alpha = 0
            self.touchRippleView.alpha = 0
            self.statusPillView.alpha = 0
        }
    }

    private func finishExtraction(with extractedImage: UIImage) {
        isExtracting = false
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
        UIView.animate(withDuration: 0.2) {
            self.backgroundImageView.transform = .identity
            self.subjectGlowView.alpha = 0
            self.touchRippleView.alpha = 0
            self.statusPillView.alpha = 0
        } completion: { [weak self] _ in
            guard let self else { return }
            let colorName = self.currentCard?.colorName ?? "스티커"
            let hexColor = self.currentCard?.hexColor ?? ""
            self.showStickerSheet(image: extractedImage, colorName: colorName, hexColor: hexColor)
            self.isOnboardingCompleted = true
        }
    }

    private func extractSubject(from image: UIImage) async throws -> UIImage {
        // Normalize orientation so that gallery photos (EXIF-rotated) render at the correct aspect ratio
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let oriented = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        guard let cgImage = oriented.cgImage else {
            throw ExtractionError.invalidImage
        }
        let ciImage = CIImage(cgImage: cgImage)
        let downsampled = ciImage.transformed(by: CGAffineTransform(scaleX: 0.5, y: 0.5))
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: downsampled)
        try handler.perform([request])
        guard let result = request.results?.first else {
            throw ExtractionError.noSubjectFound
        }
        let allInstances = result.allInstances
        guard !allInstances.isEmpty else {
            throw ExtractionError.noSubjectFound
        }
        let maskBuffer = try result.generateScaledMaskForImage(
            forInstances: allInstances,
            from: handler
        )
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let masked = downsampled.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: maskImage,
            kCIInputBackgroundImageKey: CIImage.empty()
        ])
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(masked, from: masked.extent) else {
            throw ExtractionError.renderFailed
        }
        return UIImage(cgImage: cgImage)
    }

    private func showStickerSheet(image: UIImage, colorName: String, hexColor: String) {
        let sheet = StickerExtractSheetViewController(
            stickerImage: image,
            colorName: colorName,
            hexColor: hexColor
        )
        sheet.onSave = { [weak self] in
            _ = StickerManager.shared.save(image: image, colorName: colorName, hex: hexColor)
            self?.showSuccessToast()
        }
        sheet.onCopy = { [weak self] in
            UIPasteboard.general.image = image
            self?.showCopyToast()
        }
        sheet.onShare = { [weak self] in
            guard let self else { return }
            let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self.present(activity, animated: true)
        }
        present(sheet, animated: false)
    }

    private func showSuccessToast() {
        toastTitleLabel.text = "스티커 보관함에 저장되었습니다"
        toastSubtitleLabel.text = "스티커 보관함에서 확인하세요"
        presentToast()
    }

    private func showCopyToast() {
        toastTitleLabel.text = "스티커가 복사되었습니다"
        toastSubtitleLabel.text = "다른 앱에서 붙여넣기 할 수 있어요"
        presentToast()
    }

    private func presentToast() {
        successToastView.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5
        ) {
            self.successToastView.alpha = 1
            self.successToastView.transform = .identity
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 0.3, delay: 3.0) {
                self?.successToastView.alpha = 0
            }
        }
    }

    // MARK: - Share

    private func presentShareSheet(for card: ColorCard) {
        let controls: [UIView] = [backButton, shareButton, pageCounterView, swipeLeftChevron, swipeRightChevron]
        let originalAlphas = controls.map { $0.alpha }
        controls.forEach { $0.alpha = 0 }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        zip(controls, originalAlphas).forEach { view, alpha in view.alpha = alpha }

        let coordinate = CLLocationCoordinate2D(latitude: card.latitude, longitude: card.longitude)
        var applicationActivities: [UIActivity] = []
        if card.latitude != 0 || card.longitude != 0,
           let gpsData = ImageFileManager.shared.jpegDataWithGPS(from: image, coordinate: coordinate) {
            let saveActivity = SaveToPhotosWithGPSActivity(imageData: gpsData, coordinate: coordinate)
            applicationActivities.append(saveActivity)
        }

        let shareText = L10n.colorDetailShareText
        let itemSource = ColorShareItemSource(image: image, text: shareText, title: card.colorName)

        let activityViewController = UIActivityViewController(
            activityItems: [itemSource, shareText],
            applicationActivities: applicationActivities
        )
        activityViewController.excludedActivityTypes = [.saveToCameraRoll]

        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(activityViewController, animated: true)
    }

    // MARK: - Configure

    private func configure(card: ColorCard) {
        let direction = pendingSwipeDirection
        pendingSwipeDirection = .none

        guard direction != .none else {
            applyCard(card)
            return
        }

        let slideOffset: CGFloat = direction == .left ? view.bounds.width : -view.bounds.width

        let newImageView = UIImageView(frame: view.bounds)
        newImageView.contentMode = .scaleAspectFill
        newImageView.clipsToBounds = true
        if let img = card.capturedImage {
            newImageView.image = img
        } else if let url = card.imageURL {
            newImageView.kf.setImage(with: url)
        }
        newImageView.transform = CGAffineTransform(translationX: slideOffset, y: 0)
        view.insertSubview(newImageView, belowSubview: gradientOverlayView)

        let infoViews: [UIView] = [colorNameRow, hexCodeLabel, metaLabel]

        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
            self.backgroundImageView.transform = CGAffineTransform(translationX: -slideOffset, y: 0)
            newImageView.transform = .identity
            infoViews.forEach { $0.alpha = 0 }
        } completion: { _ in
            self.applyCard(card)
            self.backgroundImageView.transform = .identity
            newImageView.removeFromSuperview()
            UIView.animate(withDuration: 0.2) {
                infoViews.forEach { $0.alpha = 1 }
            }
        }
    }

    private func applyCard(_ card: ColorCard) {
        currentCard = card
        if let img = card.capturedImage {
            backgroundImageView.image = img
        } else if let url = card.imageURL {
            backgroundImageView.kf.setImage(with: url)
        }

        colorDotView.setColor(card.dotColor)

        let nameAttr = NSMutableAttributedString(string: card.colorName)
        nameAttr.addAttribute(.kern, value: -0.5, range: NSRange(location: 0, length: card.colorName.count))
        colorNameLabel.attributedText = nameAttr

        hexCodeLabel.text = card.hexColor
        metaLabel.text = "\(card.captureDate) · \(card.locationName)"
    }
}

// MARK: - ExtractionError

private enum ExtractionError: Error {
    case invalidImage
    case noSubjectFound
    case renderFailed
}

// MARK: - SaveToPhotosWithGPSActivity

final class SaveToPhotosWithGPSActivity: UIActivity {

    private enum Constants {
        static let title = "사진에 저장"
    }

    private let imageData: Data
    private let coordinate: CLLocationCoordinate2D

    init(imageData: Data, coordinate: CLLocationCoordinate2D) {
        self.imageData = imageData
        self.coordinate = coordinate
        super.init()
    }

    override var activityTitle: String? { Constants.title }
    override var activityImage: UIImage? { UIImage(systemName: "photo.badge.plus") }
    override class var activityCategory: UIActivity.Category { .action }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool { true }
    override func prepare(withActivityItems activityItems: [Any]) {}

    override func perform() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .authorized || status == .limited {
            saveToGallery()
        } else {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                guard newStatus == .authorized || newStatus == .limited else {
                    self?.activityDidFinish(false)
                    return
                }
                self?.saveToGallery()
            }
        }
    }

    private func saveToGallery() {
        let data = imageData
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            request.addResource(with: .photo, data: data, options: options)
            request.location = location
            request.creationDate = Date()
        }) { [weak self] success, _ in
            self?.activityDidFinish(success)
        }
    }
}

// MARK: - UIActivityItemSource

final class ColorShareItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let text: String
    let title: String

    init(image: UIImage, text: String, title: String) {
        self.image = image
        self.text = text
        self.title = title
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}
