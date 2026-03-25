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
    private var cards: [ColorCard] = []
    private var currentIndex = 0

    var allCards: [ColorCard] { cards }
    var onCardTap: ((Int) -> Void)?
    var onMissionTap: (() -> Void)?

    // MARK: - UI: Header

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "ColorWalk"
        l.font = UIFont(name: "Pretendard-Bold", size: 32) ?? .boldSystemFont(ofSize: 32)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13) ?? .systemFont(ofSize: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var titleStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .leading
        return s
    }()

    private let filterButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "slider.horizontal.3")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#191F28")
        return b
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
        l.text = "아직 수집한 색이 없어요"
        l.font = UIFont(name: "Pretendard-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        l.textColor = UIColor(hex: "#191F28")
        l.textAlignment = .center
        return l
    }()

    private let emptyDescLabel: UILabel = {
        let l = UILabel()
        l.text = "산책하면서 주변의 아름다운 색을\n카메라로 담아보세요"
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

    // MARK: - UI: Carousel (existing components)

    private let carouselView = CardCarouselView()
    private let paginationView = PaginationView()
    private let detailsView = DetailsSectionView()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

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
        headerRow.addSubview(filterButton)

        view.addSubview(emptyStateStack)
        emptyCircleView.addSubview(cameraIconView)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(carouselView)
        contentView.addSubview(paginationView)
        contentView.addSubview(detailsView)

        scrollView.isHidden = true
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        headerRow.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(57)
        }
        titleStack.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        filterButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        emptyStateStack.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(view.snp.centerY).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        emptyCircleView.snp.makeConstraints { $0.width.height.equalTo(120) }
        cameraIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(48)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerRow.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        carouselView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(460)
        }

        paginationView.snp.makeConstraints {
            $0.top.equalTo(carouselView.snp.bottom).offset(22)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(8)
        }

        detailsView.snp.makeConstraints {
            $0.top.equalTo(paginationView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    // MARK: - bind

    override func bind() {
        ctaButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.onMissionTap?() })
            .disposed(by: disposeBag)

        // Observe store
        ColorCardStore.shared.cards
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] newCards in
                guard let self else { return }
                self.cards = newCards
                let isEmpty = newCards.isEmpty

                self.emptyStateStack.isHidden = !isEmpty
                self.scrollView.isHidden = isEmpty
                self.subtitleLabel.text = isEmpty
                    ? "오늘의 색을 찾아보세요"
                    : "카드를 스와이프하여 색상 컬렉션을 탐색하세요"

                guard !isEmpty else { return }

                if self.currentIndex >= newCards.count { self.currentIndex = 0 }

                self.paginationView.setup(count: newCards.count)
                self.paginationView.setActive(index: self.currentIndex)
                self.carouselView.configure(cards: newCards, currentIndex: self.currentIndex)
                self.updateDetails()
            })
            .disposed(by: disposeBag)

        // Carousel swipe events
        carouselView.swipeLeft
            .subscribe(onNext: { [weak self] in self?.advanceIndex(by: +1) })
            .disposed(by: disposeBag)

        carouselView.swipeRight
            .subscribe(onNext: { [weak self] in self?.advanceIndex(by: -1) })
            .disposed(by: disposeBag)

        carouselView.cardTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.onCardTap?(self.currentIndex)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers

    private func advanceIndex(by delta: Int) {
        guard !cards.isEmpty else { return }
        let next = (currentIndex + delta + cards.count) % cards.count
        guard next != currentIndex else { return }
        currentIndex = next
        paginationView.setActive(index: currentIndex)
        carouselView.configure(cards: cards, currentIndex: currentIndex)
        updateDetails()
    }

    private func updateDetails() {
        guard currentIndex < cards.count else { return }
        let card = cards[currentIndex]
        detailsView.setProgress(ratio: Float(card.matchPercentage) / 100.0)
        detailsView.setMission(text: "\(card.missionCurrent) / \(card.missionTotal)")
    }
}
