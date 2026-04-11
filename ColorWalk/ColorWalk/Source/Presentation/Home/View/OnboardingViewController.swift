//
//  HomeViewController.swift
//  ColorWalk
//
import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class OnboardingViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: OnboardingViewModel
    var onOnboardingComplete: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Setup

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.homeTitle
        l.font = UIFont(name: "Pretendard-Bold", size: 32) ?? .boldSystemFont(ofSize: 32)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.onboardingSubtitle
        l.font = UIFont(name: "Pretendard-Regular", size: 13) ?? .systemFont(ofSize: 13)
        l.textColor = UIColor(hex: "#6B7684")
        l.numberOfLines = 0
        return l
    }()

    private lazy var titleStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.axis = .vertical
        s.spacing = 10
        s.alignment = .leading
        return s
    }()

    private let headerRow = UIView()

    // MARK: - UI: Empty State

    private let emptyCircleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F2F4F6")
        v.layer.cornerRadius = 60
        return v
    }()

    private let cameraIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "camera")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .regular))
        iv.tintColor = UIColor(hex: "#B0B8C1")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyTitleLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.onboardingEmptyTitle
        l.font = UIFont(name: "Pretendard-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        l.textColor = UIColor(hex: "#191F28")
        l.textAlignment = .center
        return l
    }()

    private let emptyDescLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.onboardingEmptyDesc
        l.font = UIFont(name: "Pretendard-Regular", size: 13) ?? .systemFont(ofSize: 13)
        l.textColor = UIColor(hex: "#6B7684")
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    private let ctaButton: UIButton = {
        let b = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = UIColor(hex: "#191F28")
        config.background.cornerRadius = 26
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        config.image = UIImage(systemName: "camera", withConfiguration: iconConfig)
        config.baseForegroundColor = .white
        var title = AttributedString(L10n.onboardingCTAButton)
        title.font = UIFont(name: "Pretendard-SemiBold", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        title.foregroundColor = .white
        config.attributedTitle = title
        b.configuration = config
        return b
    }()

    private lazy var emptyStateStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [emptyCircleView, emptyTitleLabel, emptyDescLabel, ctaButton])
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 24
        return s
    }()

    // MARK: - Init

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    override func setupViews() {
        view.backgroundColor = .white
        view.addSubview(headerRow)
        headerRow.addSubview(titleStack)
        view.addSubview(emptyStateStack)
        emptyCircleView.addSubview(cameraIconView)
    }

    override func setupConstraints() {
        headerRow.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(57)
        }

        titleStack.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        emptyStateStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(view.snp.centerY).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        emptyCircleView.snp.makeConstraints { make in
            make.width.height.equalTo(120)
        }

        cameraIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(48)
        }
    }

    // MARK: - Bind

    override func bind() {
        ctaButton.rx.tap
            .subscribe(onNext: { [weak self] in
                AnalyticsManager.shared.logOnboardingCtaTapped()
                self?.onOnboardingComplete?()
            })
            .disposed(by: disposeBag)
    }
}
