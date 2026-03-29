//
//  MissionHomeViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import CoreLocation

final class MissionHomeViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: MissionHomeViewModel
    private var currentDisplayedMission: ColorMission = ColorMission.mockMissions[0]
    private var cards: [ColorCard] = []
    private var currentIndex: Int = 0
    private let locationManager = CLLocationManager()

    var allCards: [ColorCard] { cards }
    var onCardTap: ((Int) -> Void)?

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

    private let headerRow = UIView()

    private let debugAlertButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "bell.badge")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#FF7EB3")
        b.accessibilityLabel = "테스트 알림 발송"
        return b
    }()

    // MARK: - UI: Midnight Banner (Ay4YW)

    private let midnightBannerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F0F0F0")
        v.layer.cornerRadius = 16
        v.isHidden = true
        return v
    }()

    private let moonIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "moon.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        iv.tintColor = UIColor(hex: "#666666")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let bannerLabel: UILabel = {
        let l = UILabel()
        l.text = "자정이 지났어요! 새로운 미션이 도착했습니다"
        l.font = UIFont(name: "Pretendard-SemiBold", size: 13)
        l.textColor = UIColor(hex: "#333333")
        l.numberOfLines = 0
        return l
    }()

    // MARK: - UI: Scroll Container

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .never
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

    private let editNameButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "pencil")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)),
            for: .normal
        )
        b.tintColor = UIColor(hex: "#B0B8C1")
        b.accessibilityLabel = "이름 수정"
        return b
    }()

    private lazy var missionNameStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [missionNameLabel, editNameButton])
        s.axis = .horizontal
        s.spacing = 6
        s.alignment = .center
        return s
    }()

    private let missionDetailLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var missionTextStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [missionNameStack, missionDetailLabel])
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
        l.text = "새로운 색상을 찾으세요"
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

    private let deleteButton = AppButton(style: .secondary, title: "삭제하기")
    private let saveButton = AppButton(style: .primary, title: "저장하기")

    private lazy var actionRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [deleteButton, saveButton])
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    // MARK: - Rx

    private let shuffleSubject = PublishSubject<Void>()
    private let locationRelay = PublishRelay<CLLocation>()

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        ColorCardStore.shared.checkDailyReset()
        updateBannerVisibility()
        updateLocationLabelVisibility()
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterForeground() {
        ColorCardStore.shared.checkDailyReset()
        updateBannerVisibility()
        updateLocationLabelVisibility()
    }

    private func updateBannerVisibility() {
        let didReset = ColorCardStore.shared.didResetToday
        midnightBannerView.isHidden = !didReset

        missionSectionLabel.snp.remakeConstraints { make in
            if didReset {
                make.top.equalTo(midnightBannerView.snp.bottom).offset(36)
            } else {
                make.top.equalToSuperview().offset(36)
            }
            make.leading.equalToSuperview().offset(44)
        }

        if didReset {
            ColorCardStore.shared.didResetToday = false
        }
    }

    private func updateLocationLabelVisibility() {
        let status = locationManager.authorizationStatus
        let authorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        carouselView.updateLocationVisibility(authorized)
    }

    // MARK: - Setup

    override func setupViews() {
        view.backgroundColor = .white

        view.addSubview(headerRow)
        headerRow.addSubview(titleStack)
        headerRow.addSubview(debugAlertButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(midnightBannerView)
        midnightBannerView.addSubview(moonIconView)
        midnightBannerView.addSubview(bannerLabel)

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
        debugAlertButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.height.equalTo(36)
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

        midnightBannerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        moonIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        bannerLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.leading.equalTo(moonIconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }

        missionSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(midnightBannerView.snp.bottom).offset(36)
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
        debugAlertButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.scheduleDebugAlert()
            })
            .disposed(by: disposeBag)

        shuffleButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.handleShuffleTap()
            })
            .disposed(by: disposeBag)

        editNameButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentEditNameAlert()
            })
            .disposed(by: disposeBag)

        changeMissionButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentColorPickerSheet()
            })
            .disposed(by: disposeBag)

        deleteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentDeleteConfirmAlert()
            })
            .disposed(by: disposeBag)

        let saveImageObservable = saveButton.rx.tap
            .map { [weak self] () -> UIImage? in
                guard let self, self.currentIndex < self.cards.count else { return nil }
                return self.cards[self.currentIndex].capturedImage
            }

        let output = viewModel.transform(input: MissionHomeViewModel.Input(
            shuffleTap: shuffleSubject.asObservable(),
            changeMissionTap: Observable.empty(),
            location: locationRelay.asObservable(),
            saveTap: saveImageObservable
        ))

        output.mission
            .drive(onNext: { [weak self] mission in
                self?.applyMission(mission)
            })
            .disposed(by: disposeBag)

        output.saveResult
            .drive(onNext: { [weak self] result in
                self?.handleSaveResult(result)
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

    // MARK: - Debug

    private func scheduleDebugAlert() {
        MissionAlertScheduler.shared.scheduleImmediateTest(after: 5)
        let alert = UIAlertController(title: "테스트 알림", message: "5초 후 알림이 발송됩니다.\n앱을 백그라운드로 내려주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helper

    private func handleSaveResult(_ result: GallerySaveResult) {
        switch result {
        case .success:
            showSaveAlert(title: "저장 완료", message: "사진이 갤러리에 저장되었습니다.", showSettings: false)
        case .failure:
            showSaveAlert(title: "저장 실패", message: "사진 저장 중 오류가 발생했습니다.", showSettings: false)
        case .permissionDenied:
            showSaveAlert(title: "사진 저장 권한 필요", message: "설정에서 사진 접근 권한을 허용해주세요.", showSettings: true)
        }
    }

    private func showSaveAlert(title: String, message: String, showSettings: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if showSettings {
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            })
        } else {
            alert.addAction(UIAlertAction(title: "확인", style: .default))
        }
        present(alert, animated: true)
    }

    private func handleShuffleTap() {
        guard !cards.isEmpty else {
            shuffleSubject.onNext(())
            return
        }
        let alert = UIAlertController(
            title: "미션 색상 변경",
            message: "현재 촬영한 사진이 모두 초기화되며 저장되지 않습니다. 계속하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { [weak self] _ in
            ColorCardStore.shared.clearAll()
            self?.shuffleSubject.onNext(())
        })
        present(alert, animated: true)
    }

    private func advanceIndex(by delta: Int) {
        guard !cards.isEmpty else { return }
        let next = currentIndex + delta
        guard next >= 0 && next < cards.count else { return }
        currentIndex = next
        paginationView.setActive(index: currentIndex)
        carouselView.configure(cards: cards, currentIndex: currentIndex)
    }

    // MARK: - Sheet Presentation

    private func presentDeleteConfirmAlert() {
        let alert = UIAlertController(
            title: "사진 삭제",
            message: "해당 사진을 정말 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            ColorCardStore.shared.remove(at: self.currentIndex)
        })
        present(alert, animated: true)
    }

    private func presentColorPickerSheet() {
        let sheet = ColorPickerSheetViewController(currentMission: currentDisplayedMission)
        sheet.modalPresentationStyle = .overFullScreen
        sheet.onApply = { [weak self] color, hex, name in
            self?.applyCustomColor(color, hex: hex, name: name)
        }
        present(sheet, animated: false)
    }

    private func presentEditNameAlert() {
        let alert = UIAlertController(title: "이름 수정", message: "미션의 이름을 입력해주세요", preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.text = self?.currentDisplayedMission.name
            tf.placeholder = "미션 이름"
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "변경", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.updateMissionName(name)
        })
        present(alert, animated: true)
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

        ColorMissionStore.shared.setMission(mission)
        RealmManager.shared.updateTodayMission(hex: mission.hexColor, name: mission.name)
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

    private func applyCustomColor(_ color: UIColor, hex: String, name: String) {
        UIView.animate(withDuration: 0.3) {
            self.colorDotView.backgroundColor = color
            self.progressFill.backgroundColor = color
            self.progressCountLabel.textColor = color
        }

        missionNameLabel.text = name
        missionDetailLabel.text = "\(hex)  ·  \(currentDisplayedMission.weatherInfo)"

        let updated = ColorMission(
            name: name,
            hexColor: hex,
            color: color,
            weatherInfo: currentDisplayedMission.weatherInfo,
            progress: currentDisplayedMission.progress
        )
        currentDisplayedMission = updated
        ColorMissionStore.shared.setMission(updated)
        RealmManager.shared.updateTodayMission(hex: hex, name: name)
    }

    private func updateMissionName(_ name: String) {
        missionNameLabel.text = name
        let updated = ColorMission(
            name: name,
            hexColor: currentDisplayedMission.hexColor,
            color: currentDisplayedMission.color,
            weatherInfo: currentDisplayedMission.weatherInfo,
            progress: currentDisplayedMission.progress
        )
        currentDisplayedMission = updated
        ColorMissionStore.shared.setMission(updated)
    }
}

// MARK: - CLLocationManagerDelegate

extension MissionHomeViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateLocationLabelVisibility()
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationRelay.accept(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
