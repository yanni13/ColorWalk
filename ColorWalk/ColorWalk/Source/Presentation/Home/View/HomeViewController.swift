//
//  HomeViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class HomeViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: HomeViewModel
    var allCards: [ColorCard] = ColorCard.mockCards
    var onCardTap: ((Int) -> Void)?
    var onMissionTap: (() -> Void)?

    // MARK: - UI: Header
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "ColorWalk"
        l.font = UIFont(name: "Pretendard-Bold", size: 28)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "오늘의 색을 찾아보세요"
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var titleStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.axis = .vertical
        s.spacing = 2
        s.alignment = .leading
        return s
    }()

    private let bellButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "bell")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#191F28")
        return b
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E8EB")
        v.layer.cornerRadius = 16
        return v
    }()

    private lazy var rightStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [bellButton, avatarView])
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private let headerRow: UIView = UIView()

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
        l.text = "아직 수집한 색이 없어요"
        l.font = UIFont(name: "Pretendard-Bold", size: 18)
        l.textColor = UIColor(hex: "#191F28")
        l.textAlignment = .center
        return l
    }()

    private let emptyDescLabel: UILabel = {
        let l = UILabel()
        l.text = "산책하면서 주변의 아름다운 색을\n카메라로 담아보세요"
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
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

        var title = AttributedString("오늘의 첫 번째 색을 찾아볼까요?")
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

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - setupViews

    override func setupViews() {
        view.backgroundColor = .white

        view.addSubview(headerRow)
        headerRow.addSubview(titleStack)
        headerRow.addSubview(rightStack)

        view.addSubview(emptyStateStack)
        emptyCircleView.addSubview(cameraIconView)
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        headerRow.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(57)
        }

        titleStack.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }

        rightStack.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        bellButton.snp.makeConstraints {
            $0.width.height.equalTo(22)
        }

        avatarView.snp.makeConstraints {
            $0.width.height.equalTo(32)
        }

        emptyStateStack.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(view.snp.centerY).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        emptyCircleView.snp.makeConstraints {
            $0.width.height.equalTo(120)
        }

        cameraIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(48)
        }
    }

    // MARK: - bind

    override func bind() {
        ctaButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onMissionTap?()
            })
            .disposed(by: disposeBag)
    }
}
