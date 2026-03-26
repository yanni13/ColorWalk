//
//  MissionHomeViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MissionHomeViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: MissionHomeViewModel
    private var currentDisplayedMission: ColorMission = ColorMission.mockMissions[0]
    private var cards: [ColorCard] = []
    private var currentIndex: Int = 0

    var allCards: [ColorCard] { cards }
    var onCardTap: ((Int) -> Void)?
    var onRetake: (() -> Void)?
    var onSave: (() -> Void)?

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
        l.text = "새로운 하루, 새로운 색!"
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
        b.accessibilityLabel = "알림"
        return b
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E5E8EB")
        v.layer.cornerRadius = 16
        v.accessibilityLabel = "프로필"
        return v
    }()

    private lazy var rightStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [bellButton, avatarView])
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private let headerRow = UIView()

    // MARK: - UI: Scroll Container

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

    // MARK: - UI: Mission Card

    private let missionSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "오늘의 미션"
        l.font = UIFont(name: "Pretendard-SemiBold", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(hex: "#ECEEF2").cgColor
        return v
    }()

    private let colorDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.backgroundColor = UIColor(hex: "#34D399")
        return v
    }()

    private let missionNameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 18)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let missionDetailLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var missionTextStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [missionNameLabel, missionDetailLabel])
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .leading
        return s
    }()

    private let shuffleButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "arrow.2.circlepath")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#B0B8C1")
        b.accessibilityLabel = "미션 셔플"
        return b
    }()

    // MARK: - UI: Progress Header (aqAvY)

    private let progressSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "수집 현황"
        l.font = UIFont(name: "Pretendard-Medium", size: 12)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let progressCountLabel: UILabel = {
        let l = UILabel()
        l.text = "0 / 9 완료"
        l.font = UIFont(name: "Pretendard-Bold", size: 12)
        l.textColor = UIColor(hex: "#34D399")
        return l
    }()

    private lazy var progressHeaderRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [progressSectionLabel, progressCountLabel])
        s.axis = .horizontal
        s.distribution = .equalSpacing
        return s
    }()

    private let progressTrack: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F2F4F6")
        v.layer.cornerRadius = 4
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.backgroundColor = UIColor(hex: "#34D399")
        return v
    }()

    // MARK: - UI: Change Mission

    private let changeMissionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("색상이 마음에 안 드시나요?  →", for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Regular", size: 14)
        b.tintColor = UIColor(hex: "#6B7684")
        b.accessibilityLabel = "미션 색상 변경"
        return b
    }()

    // MARK: - UI: Home Container

    private let homeContainerView = UIView()

    private let heroCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 12
        v.layer.shadowOpacity = 1.0
        return v
    }()

    private let heroIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "photo")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .regular))
        iv.tintColor = UIColor(hex: "#B0B8C1")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let heroPlaceholderLabel: UILabel = {
        let l = UILabel()
        l.text = "첫 촬영 후 여기에 사진이 표시됩니다"
        l.font = UIFont(name: "Pretendard-Medium", size: 13)
        l.textColor = UIColor(hex: "#B0B8C1")
        l.textAlignment = .center
        return l
    }()

    private lazy var heroContentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [heroIconView, heroPlaceholderLabel])
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 12
        return s
    }()

    // MARK: - UI: Photo Section

    private let photoSectionLabel: UILabel = {
        let l = UILabel()
        l.text = "촬영한 사진"
        l.font = UIFont(name: "Pretendard-Bold", size: 16)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let photoCountLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Medium", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var carSectionHeader: UIStackView = {
        let s = UIStackView(arrangedSubviews: [photoSectionLabel, photoCountLabel])
        s.axis = .horizontal
        s.distribution = .equalSpacing
        s.alignment = .center
        return s
    }()

    private let carouselView = CardCarouselView()
    private let paginationView = PaginationView()

    // MARK: - UI: Action Row

    private let retakeButton = AppButton(style: .secondary, title: "다시 촬영")
    private let saveButton = AppButton(style: .primary, title: "저장하기")

    private lazy var actionRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [retakeButton, saveButton])
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    // MARK: - Rx

    private let shuffleSubject = PublishSubject<Void>()

    // MARK: - Constants

    private enum Constants {
        static let carouselHeight: CGFloat = 460
        static let paginationHeight: CGFloat = 8
        static let heroIconSize: CGFloat = 32
        static let actionRowHeight: CGFloat = 52
    }

    // MARK: - Init

    init(viewModel: MissionHomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func setupViews() {
        view.backgroundColor = .white

        view.addSubview(headerRow)
        headerRow.addSubview(titleStack)
        headerRow.addSubview(rightStack)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(missionSectionLabel)
        contentView.addSubview(cardView)
        cardView.addSubview(colorDotView)
        cardView.addSubview(missionTextStack)
        cardView.addSubview(shuffleButton)
        cardView.addSubview(progressHeaderRow)
        cardView.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)

        contentView.addSubview(changeMissionButton)
        contentView.addSubview(homeContainerView)

        homeContainerView.addSubview(heroCardView)
        heroCardView.addSubview(heroContentStack)
        homeContainerView.addSubview(carSectionHeader)
        homeContainerView.addSubview(carouselView)
        homeContainerView.addSubview(paginationView)
        homeContainerView.addSubview(actionRow)

        carSectionHeader.isHidden = true
        carouselView.isHidden = true
        paginationView.isHidden = true
        actionRow.isHidden = true
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
        rightStack.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        bellButton.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        missionSectionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(36)
            make.leading.equalToSuperview().offset(44)
        }
        cardView.snp.makeConstraints { make in
            make.top.equalTo(missionSectionLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        colorDotView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalTo(missionTextStack)
            make.width.height.equalTo(40)
        }
        missionTextStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalTo(colorDotView.snp.trailing).offset(12)
            make.trailing.equalTo(shuffleButton.snp.leading).offset(-12)
        }
        shuffleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(missionTextStack)
            make.width.height.equalTo(28)
        }
        progressHeaderRow.snp.makeConstraints { make in
            make.top.equalTo(missionTextStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        progressTrack.snp.makeConstraints { make in
            make.top.equalTo(progressHeaderRow.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(8)
            make.bottom.equalToSuperview().inset(20)
        }
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        changeMissionButton.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        homeContainerView.snp.makeConstraints { make in
            make.top.equalTo(changeMissionButton.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(24)
            make.height.greaterThanOrEqualTo(200)
        }

        heroCardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(180)
        }
        heroContentStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        heroIconView.snp.makeConstraints { make in
            make.width.height.equalTo(Constants.heroIconSize)
        }

        carSectionHeader.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        carouselView.snp.makeConstraints { make in
            make.top.equalTo(carSectionHeader.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.carouselHeight)
        }
        paginationView.snp.makeConstraints { make in
            make.top.equalTo(carouselView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(Constants.paginationHeight)
        }
        actionRow.snp.makeConstraints { make in
            make.top.equalTo(paginationView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(Constants.actionRowHeight)
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Bind

    override func bind() {
        shuffleButton.rx.tap
            .bind(to: shuffleSubject)
            .disposed(by: disposeBag)

        changeMissionButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentColorPickerSheet()
            })
            .disposed(by: disposeBag)

        retakeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onRetake?()
            })
            .disposed(by: disposeBag)

        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onSave?()
            })
            .disposed(by: disposeBag)

        let output = viewModel.transform(input: MissionHomeViewModel.Input(
            shuffleTap: shuffleSubject.asObservable(),
            changeMissionTap: Observable.empty()
        ))

        output.mission
            .drive(onNext: { [weak self] mission in
                self?.applyMission(mission)
            })
            .disposed(by: disposeBag)

        ColorCardStore.shared.cards
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] newCards in
                guard let self else { return }
                self.cards = newCards
                let isEmpty = newCards.isEmpty
                self.heroCardView.isHidden = !isEmpty
                self.carSectionHeader.isHidden = isEmpty
                self.carouselView.isHidden = isEmpty
                self.paginationView.isHidden = isEmpty
                self.actionRow.isHidden = isEmpty

                self.progressCountLabel.text = "\(newCards.count) / 9 완료"
                self.updateProgressBar(count: newCards.count)

                guard !isEmpty else { return }
                if self.currentIndex >= newCards.count { self.currentIndex = 0 }
                self.photoCountLabel.text = "\(newCards.count) / 9장"
                self.paginationView.setup(count: newCards.count)
                self.paginationView.setActive(index: self.currentIndex)
                self.carouselView.configure(cards: newCards, currentIndex: self.currentIndex)
            })
            .disposed(by: disposeBag)

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

    // MARK: - Helper

    private func advanceIndex(by delta: Int) {
        guard !cards.isEmpty else { return }
        let next = (currentIndex + delta + cards.count) % cards.count
        guard next != currentIndex else { return }
        currentIndex = next
        paginationView.setActive(index: currentIndex)
        carouselView.configure(cards: cards, currentIndex: currentIndex)
    }

    // MARK: - Sheet Presentation

    private func presentColorPickerSheet() {
        let sheet = ColorPickerSheetViewController(currentMission: currentDisplayedMission)
        sheet.modalPresentationStyle = .overFullScreen
        sheet.onApply = { [weak self] color, hex in
            self?.applyCustomColor(color, hex: hex)
        }
        present(sheet, animated: false)
    }

    // MARK: - Apply

    private func applyMission(_ mission: ColorMission) {
        currentDisplayedMission = mission

        UIView.animate(withDuration: 0.25) {
            self.colorDotView.backgroundColor = mission.color
            self.progressFill.backgroundColor = mission.color
            self.progressCountLabel.textColor = mission.color
        }

        missionNameLabel.text = mission.name
        missionDetailLabel.text = "\(mission.hexColor)  ·  \(mission.weatherInfo)"

        let count = ColorCardStore.shared.cards.value.count
        updateProgressBar(count: count)
    }

    private func updateProgressBar(count: Int) {
        progressFill.snp.updateConstraints { make in make.width.equalTo(0) }
        view.layoutIfNeeded()

        let ratio = min(CGFloat(count) / 9.0, 1.0)
        let targetWidth = progressTrack.bounds.width * ratio
        progressFill.snp.updateConstraints { make in make.width.equalTo(targetWidth) }
        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut) {
            self.progressTrack.layoutIfNeeded()
        }
    }

    private func applyCustomColor(_ color: UIColor, hex: String) {
        UIView.animate(withDuration: 0.3) {
            self.colorDotView.backgroundColor = color
            self.progressFill.backgroundColor = color
            self.progressCountLabel.textColor = color
        }

        missionDetailLabel.text = "\(hex)  ·  \(currentDisplayedMission.weatherInfo)"

        let updated = ColorMission(
            name: currentDisplayedMission.name,
            hexColor: hex,
            color: color,
            weatherInfo: currentDisplayedMission.weatherInfo,
            progress: currentDisplayedMission.progress
        )
        currentDisplayedMission = updated
    }
}
