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
    private var currentIndex: Int = 0
    var onCardTap: ((Int) -> Void)?

    // MARK: - UI: Scroll
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.showsHorizontalScrollIndicator = false
        return s
    }()
    private let contentView = UIView()

    // MARK: - UI: Header
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Gallery"
        l.font = UIFont(name: "Pretendard-Bold", size: 32)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let searchButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "magnifyingglass")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#6B7684")
        return b
    }()

    private let filterButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "slider.horizontal.3")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#6B7684")
        return b
    }()

    private lazy var titleRow: UIView = {
        let v = UIView()
        let actions = UIStackView(arrangedSubviews: [searchButton, filterButton])
        actions.axis = .horizontal
        actions.spacing = 16
        actions.alignment = .center
        v.addSubview(titleLabel)
        v.addSubview(actions)
        titleLabel.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        actions.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }
        return v
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "카드를 스와이프하여 색상 컬렉션을 탐색하세요"
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var headerStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleRow, subtitleLabel])
        s.axis = .vertical
        s.spacing = 4
        return s
    }()

    // MARK: - UI: Content
    private let carouselView = CardCarouselView()
    private let paginationView = PaginationView()
    private let detailsSectionView = DetailsSectionView()

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

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [headerStack, carouselView, paginationView, detailsSectionView].forEach {
            contentView.addSubview($0)
        }

        paginationView.setup(count: allCards.count)
        carouselView.configure(cards: allCards, currentIndex: 0)
        titleLabel.setKern(-0.5)
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(view)
        }

        headerStack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        titleRow.snp.makeConstraints {
            $0.height.equalTo(44)
        }

        carouselView.snp.makeConstraints {
            $0.top.equalTo(headerStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(452)
        }

        paginationView.snp.makeConstraints {
            $0.top.equalTo(carouselView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(16)
        }

        detailsSectionView.snp.makeConstraints {
            $0.top.equalTo(paginationView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().inset(24)
        }

        searchButton.snp.makeConstraints { $0.width.height.equalTo(22) }
        filterButton.snp.makeConstraints { $0.width.height.equalTo(22) }
    }

    // MARK: - bind

    override func bind() {
        let input = HomeViewModel.Input(
            swipeLeft: carouselView.swipeLeft,
            swipeRight: carouselView.swipeRight,
            shareTap: detailsSectionView.shareTap,
            saveTap: detailsSectionView.saveTap
        )

        let output = viewModel.transform(input: input)

        output.currentIndex
            .drive(onNext: { [weak self] index in
                guard let self else { return }
                self.currentIndex = index
                self.carouselView.configure(cards: self.allCards, currentIndex: index)
                self.paginationView.setActive(index: index)
                self.scrollToDetails()
            })
            .disposed(by: disposeBag)

        output.progressRatio
            .drive(onNext: { [weak self] ratio in
                self?.detailsSectionView.setProgress(ratio: ratio)
            })
            .disposed(by: disposeBag)

        output.missionText
            .drive(onNext: { [weak self] text in
                self?.detailsSectionView.setMission(text: text)
            })
            .disposed(by: disposeBag)

        carouselView.cardTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.onCardTap?(self.currentIndex)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers

    private func scrollToDetails() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            let origin = self.detailsSectionView.convert(CGPoint.zero, to: self.scrollView)
            let rect = CGRect(origin: origin, size: self.detailsSectionView.frame.size)
            self.scrollView.scrollRectToVisible(rect, animated: true)
        }
    }
}

