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
    private var currentDisplayedMission: ColorMission = ColorMission.placeholder
    private var currentWeatherData: WeatherData?
    private var cards: [ColorCard] = []
    private var currentIndex: Int = 0
    private let locationManager = CLLocationManager()

    var allCards: [ColorCard] { cards }
    var onCardTap: ((Int) -> Void)?
    var onStickerVaultTap: (() -> Void)?

    // MARK: - UI: Header

    private let stickerVaultButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: "sparkles", withConfiguration: config), for: .normal)
        b.tintColor = UIColor(hex: "#191F28")
        b.accessibilityLabel = "스티커 보관함"
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.homeTitle
        l.font = UIFont(name: "Pretendard-Bold", size: 28)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private lazy var titleStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel])
        s.axis = .vertical
        s.spacing = 2
        s.alignment = .leading
        return s
    }()

    private let headerRow = UIView()

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
        l.text = L10n.homeMidnightBanner
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
        l.text = L10n.homeMissionSection
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
        b.accessibilityLabel = L10n.accessibilityEditName
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
        l.numberOfLines = 0 // 날씨 정보 잘림 방지
        return l
    }()

    private lazy var missionTextStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [missionNameStack, missionDetailLabel])
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .leading
        s.isLayoutMarginsRelativeArrangement = true
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
        b.accessibilityLabel = L10n.accessibilityShuffleMission
        return b
    }()

    // MARK: - UI: Progress Header (aqAvY)

    private let progressSectionLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.homeProgressSection
        l.font = UIFont(name: "Pretendard-Medium", size: 12)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let progressCountLabel: UILabel = {
        let l = UILabel()
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
        b.setTitle(L10n.homeChangeMissionButton, for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Regular", size: 14)
        b.tintColor = UIColor(hex: "#6B7684")
        b.accessibilityLabel = L10n.alertMissionChangeTitle
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
        l.text = L10n.homePlaceholder
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
        l.text = L10n.homePhotosSection
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
    private let weatherAttributionView = WeatherAttributionView()

    // MARK: - UI: Action Row

    private let deleteButton = AppButton(style: .secondary, title: L10n.buttonDeleteAction)
    private let saveButton = AppButton(style: .primary, title: L10n.buttonSave)

    private lazy var actionRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [deleteButton, saveButton])
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    // MARK: - Gradient

    private let backgroundGradientLayer = CAGradientLayer()
    private var currentGradientColor: UIColor = UIColor(hex: "#B0B8C1")

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        if backgroundGradientLayer.colors == nil {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundGradientLayer.colors = [
                currentGradientColor.withAlphaComponent(0.33).cgColor,
                currentGradientColor.withAlphaComponent(0.22).cgColor,
                currentGradientColor.withAlphaComponent(0.10).cgColor,
                UIColor.clear.cgColor
            ]
            CATransaction.commit()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        ColorCardStore.shared.checkDailyReset()
        updateBannerVisibility()
        updateLocationLabelVisibility()
        refreshCountLabels()
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
        updateLocationLabelVisibility()
    }

    private func updateBannerVisibility() {
        let didReset = ColorCardStore.shared.didResetToday
        midnightBannerView.isHidden = !didReset

        missionSectionLabel.snp.remakeConstraints { make in
            if didReset {
                make.top.equalTo(midnightBannerView.snp.bottom).offset(20)
            } else {
                make.top.equalToSuperview().offset(20)
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
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        backgroundGradientLayer.locations = [0, 0.4, 0.7, 1.0]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        view.addSubview(headerRow)
        headerRow.addSubview(titleStack)
        headerRow.addSubview(stickerVaultButton)

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
        homeContainerView.addSubview(weatherAttributionView)

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
        stickerVaultButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.height.equalTo(44)
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
            make.top.equalToSuperview().offset(10)
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
            make.top.equalTo(midnightBannerView.snp.bottom).offset(20)
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
        }
        
        weatherAttributionView.snp.makeConstraints { make in
            make.top.equalTo(actionRow.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(24)
        }

    }

    // MARK: - Bind

    override func bind() {
        stickerVaultButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onStickerVaultTap?()
            })
            .disposed(by: disposeBag)

        // 카드뷰 탭 시 상세 모달 표시
        let cardTap = UITapGestureRecognizer()
        cardView.addGestureRecognizer(cardTap)
        cardTap.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.presentMissionDetailSheet()
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
                self?.handleColorPickerTap()
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

        output.weatherData
            .drive(onNext: { [weak self] data in
                guard let self else { return }
                self.currentWeatherData = data
                let newWeatherInfo = data.displayText == L10n.missionWeatherNoInfo
                    ? L10n.missionWeatherLoading
                    : L10n.missionWeatherInfoFormat(data.displayText)
                self.missionDetailLabel.text = "\(self.currentDisplayedMission.hexColor)  ·  \(newWeatherInfo)"
                self.currentDisplayedMission = ColorMission(
                    name: self.currentDisplayedMission.name,
                    hexColor: self.currentDisplayedMission.hexColor,
                    color: self.currentDisplayedMission.color,
                    weatherInfo: newWeatherInfo,
                    progress: self.currentDisplayedMission.progress
                )
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

                let total = self.currentGridSlotCount
                self.progressCountLabel.text = L10n.homeProgressCount(captured: newCards.count, total: total)
                self.updateProgressBar(count: newCards.count)

                guard !isEmpty else { return }
                if self.currentIndex >= newCards.count { self.currentIndex = 0 }
                self.photoCountLabel.text = L10n.homePhotosCount(captured: newCards.count, total: total)
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

    private var currentGridSlotCount: Int {
        guard let raw = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKey.gridLayout),
              let layout = GridLayoutType(rawValue: raw) else {
            return GridLayoutType.threeByThree.slotCount
        }
        return layout.slotCount
    }

    private func refreshCountLabels() {
        let count = ColorCardStore.shared.cards.value.count
        let total = currentGridSlotCount
        progressCountLabel.text = L10n.homeProgressCount(captured: count, total: total)
        updateProgressBar(count: count)
        if !cards.isEmpty {
            photoCountLabel.text = L10n.homePhotosCount(captured: count, total: total)
        }
    }

    private func handleSaveResult(_ result: GallerySaveResult) {
        switch result {
        case .success:
            showSaveAlert(title: L10n.alertSaveSuccessTitle, message: L10n.alertSaveSuccessMessage, showSettings: false)
        case .failure:
            showSaveAlert(title: L10n.alertSaveFailureTitle, message: L10n.alertSaveFailureMessage, showSettings: false)
        case .permissionDenied:
            showSaveAlert(title: L10n.alertSavePermissionTitle, message: L10n.alertSavePermissionMessage, showSettings: true)
        }
    }

    private func showSaveAlert(title: String, message: String, showSettings: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if showSettings {
            alert.addAction(UIAlertAction(title: L10n.buttonCancel, style: .cancel))
            alert.addAction(UIAlertAction(title: L10n.buttonOpenSettings, style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            })
        } else {
            alert.addAction(UIAlertAction(title: L10n.buttonConfirm, style: .default))
        }
        present(alert, animated: true)
    }

    private func handleShuffleTap() {
        guard !cards.isEmpty else {
            AnalyticsManager.shared.logMissionShuffled()
            shuffleSubject.onNext(())
            return
        }
        let alert = UIAlertController(
            title: L10n.alertMissionChangeTitle,
            message: L10n.alertMissionChangeMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.buttonCancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.buttonConfirm, style: .destructive) { [weak self] _ in
            AnalyticsManager.shared.logMissionShuffled()
            ColorCardStore.shared.clearAll()
            self?.shuffleSubject.onNext(())
        })
        present(alert, animated: true)
    }

    private func handleColorPickerTap() {
        guard !cards.isEmpty else {
            presentColorPickerSheet()
            return
        }
        let alert = UIAlertController(
            title: L10n.alertMissionChangeTitle,
            message: L10n.alertMissionChangeMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.buttonCancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.buttonConfirm, style: .destructive) { [weak self] _ in
            self?.presentColorPickerSheet()
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
            title: L10n.alertPhotoDeleteTitle,
            message: L10n.alertPhotoDeleteMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.buttonCancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.buttonDelete, style: .destructive) { [weak self] _ in
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
        let alert = UIAlertController(title: L10n.alertEditNameTitle, message: L10n.alertEditNameMessage, preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.text = self?.currentDisplayedMission.name
            tf.placeholder = L10n.textFieldMissionNamePlaceholder
        }
        alert.addAction(UIAlertAction(title: L10n.buttonCancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.buttonChange, style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.updateMissionName(name)
        })
        present(alert, animated: true)
    }


    private func presentMissionDetailSheet() {
        guard let weather = currentWeatherData else { return }
        let sheet = MissionDetailSheetViewController(mission: currentDisplayedMission, weatherData: weather)
        sheet.onNameUpdate = { [weak self] newName in
            self?.updateMissionName(newName)
        }
        present(sheet, animated: false)
    }

    // MARK: - Apply

    private func applyMission(_ mission: ColorMission) {
        // 이미 로드된 날씨 정보가 있으면 유지, 없으면 로딩 텍스트 표시
        let preservedWeather = currentDisplayedMission.weatherInfo == L10n.missionWeatherNoInfo
            ? L10n.missionWeatherLoading
            : currentDisplayedMission.weatherInfo
        currentDisplayedMission = ColorMission(
            name: mission.name,
            hexColor: mission.hexColor,
            color: mission.color,
            weatherInfo: preservedWeather,
            progress: mission.progress
        )

        UIView.animate(withDuration: 0.25) {
            self.colorDotView.backgroundColor = mission.color
            self.progressFill.backgroundColor = mission.color
            self.progressCountLabel.textColor = mission.color
        }
        applyGradient(for: mission.color)

        missionNameLabel.text = mission.name
        missionDetailLabel.text = "\(mission.hexColor)  ·  \(preservedWeather)"

        let count = ColorCardStore.shared.cards.value.count
        updateProgressBar(count: count)

        ColorMissionStore.shared.setMission(mission)
        RealmManager.shared.updateTodayMission(hex: mission.hexColor, name: mission.name, weather: mission.weatherInfo)
        WidgetDataWriter.shared.updateWidgetData(with: mission)
    }

    private func applyGradient(for color: UIColor) {
        currentGradientColor = color
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        backgroundGradientLayer.colors = [
            color.withAlphaComponent(0.33).cgColor,
            color.withAlphaComponent(0.22).cgColor,
            color.withAlphaComponent(0.10).cgColor,
            UIColor.clear.cgColor
        ]
        CATransaction.commit()
    }

    private func updateProgressBar(count: Int) {
        progressFill.snp.updateConstraints { make in make.width.equalTo(0) }
        view.layoutIfNeeded()

        let total = CGFloat(currentGridSlotCount)
        let ratio = min(CGFloat(count) / total, 1.0)
        let targetWidth = progressTrack.bounds.width * ratio
        progressFill.snp.updateConstraints { make in make.width.equalTo(targetWidth) }
        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut) {
            self.progressTrack.layoutIfNeeded()
        }
    }

    private func applyCustomColor(_ color: UIColor, hex: String, name: String) {
        AnalyticsManager.shared.logMissionColorChanged(hexColor: hex, colorName: name)
        ColorCardStore.shared.clearAll()

        UIView.animate(withDuration: 0.3) {
            self.colorDotView.backgroundColor = color
            self.progressFill.backgroundColor = color
            self.progressCountLabel.textColor = color
        }
        applyGradient(for: color)

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
        RealmManager.shared.updateTodayMission(hex: hex, name: name, weather: updated.weatherInfo)
        WidgetDataWriter.shared.updateWidgetData(with: updated)
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
        RealmManager.shared.updateTodayMission(hex: updated.hexColor, name: updated.name, weather: updated.weatherInfo)
        WidgetDataWriter.shared.updateWidgetData(with: updated)
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
