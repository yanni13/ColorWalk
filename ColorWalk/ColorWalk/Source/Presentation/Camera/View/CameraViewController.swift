//
//  CameraViewController.swift
//  ColorWalk
//

import UIKit
import AVFoundation
import SnapKit
import RxSwift
import RxCocoa
import PhotosUI
import CoreLocation
import ImageIO
import UniformTypeIdentifiers

// MARK: - GridView (3x3)
private final class GridView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isHidden = true
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1.0)

        let w = rect.width
        let h = rect.height

        // 세로선
        context.move(to: CGPoint(x: w / 3, y: 0))
        context.addLine(to: CGPoint(x: w / 3, y: h))
        context.move(to: CGPoint(x: 2 * w / 3, y: 0))
        context.addLine(to: CGPoint(x: 2 * w / 3, y: h))

        // 가로선
        context.move(to: CGPoint(x: 0, y: h / 3))
        context.addLine(to: CGPoint(x: w, y: h / 3))
        context.move(to: CGPoint(x: 0, y: 2 * h / 3))
        context.addLine(to: CGPoint(x: w, y: 2 * h / 3))

        context.strokePath()
    }
}

private final class FocusSquareView: UIView {
    private enum Constants {
        static let cornerLength: CGFloat = 12
        static let lineWidth: CGFloat    = 2
        static let size: CGFloat         = 70
    }

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: Constants.size, height: Constants.size))
        backgroundColor = .clear
        isUserInteractionEnabled = false
        alpha = 0
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(Constants.lineWidth)

        let cl = Constants.cornerLength
        ctx.move(to: CGPoint(x: rect.minX, y: rect.minY + cl))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.minX + cl, y: rect.minY))

        ctx.move(to: CGPoint(x: rect.maxX - cl, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cl))

        ctx.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cl))
        ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.maxX - cl, y: rect.maxY))

        ctx.move(to: CGPoint(x: rect.minX + cl, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cl))

        ctx.strokePath()
    }
}

final class CameraViewController: BaseViewController {

    // MARK: - Callbacks
    var onBack: (() -> Void)?

    // MARK: - ViewModel
    private let viewModel = CameraViewModel()
    private let locationManager = CLLocationManager()
    private var currentZoomFactor: CGFloat = 1.0

    // Timer state
    private var isCountingDown = false

    private var timerSeconds: Int = 0 {
        didSet {
            let isActive = timerSeconds > 0
            let iconName = isActive ? "timer.circle.fill" : "timer"

            timerButton.setImage(
                UIImage(systemName: iconName)?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
                for: .normal
            )
            timerButton.tintColor = isActive ? UIColor(hex: "#34D399") : .white
            timerLabel.text = isActive ? "\(timerSeconds)s" : ""
            timerLabel.textColor = .white
        }
    }

    // MARK: - Preview
    private let previewView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .black
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let gridView = GridView()
    private let focusSquareView = FocusSquareView()

    // MARK: - Navigation Bar
    private let navBar = UIView()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "chevron.left")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
            for: .normal
        )
        b.tintColor = .white
        return b
    }()

    private let navTitleLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.cameraTitle
        l.font = UIFont(name: "Pretendard-Bold", size: 17) ?? .boldSystemFont(ofSize: 17)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let gridButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "grid")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
            for: .normal
        )
        b.tintColor = .white
        return b
    }()

    private let timerButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "timer")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
            for: .normal
        )
        b.tintColor = .white
        return b
    }()

    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 12)
        l.textColor = .white
        return l
    }()

    private let countdownLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 80)
        l.textColor = .white
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private let doneButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Done", for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        b.tintColor = .white
        return b
    }()

    // MARK: - Viewfinder
    private let crosshairView = CrosshairView()
    private let colorPillView = ColorDetectPillView()

    // MARK: - Filter Strip
    private let filterStrip = CameraFilterStripView()

    // MARK: - Bottom Controls
    private let missionPill: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        v.layer.cornerRadius = 19
        return v
    }()

    private let missionIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "scope")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let missionLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13) ?? .systemFont(ofSize: 13)
        l.textColor = .white
        l.text = L10n.cameraMissionLabel("Sky Blue")
        return l
    }()

    // Thumbnail (last captured photo preview)
    private let thumbnailButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(hex: "#2B2B2B")
        b.layer.cornerRadius = 10
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        b.clipsToBounds = true
        return b
    }()

    // Shutter
    private let shutterButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = .clear
        b.layer.cornerRadius = 36
        b.layer.borderWidth = 3
        b.layer.borderColor = UIColor.white.cgColor

        let inner = UIView()
        inner.isUserInteractionEnabled = false
        inner.backgroundColor = .white
        inner.layer.cornerRadius = 28
        b.addSubview(inner)
        inner.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(56)
        }
        return b
    }()

    // Flip camera
    private let flipButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "arrow.triangle.2.circlepath.camera")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)),
            for: .normal
        )
        b.tintColor = .white
        b.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        b.layer.cornerRadius = 24
        return b
    }()


    // MARK: - setupViews

    override func setupViews() {
        view.backgroundColor = .black

        view.addSubview(previewView)
        view.addSubview(gridView)
        view.addSubview(navBar)
        navBar.addSubview(backButton)
        navBar.addSubview(navTitleLabel)
        navBar.addSubview(gridButton)
        navBar.addSubview(timerButton)
        timerButton.addSubview(timerLabel)
        navBar.addSubview(doneButton)

        view.addSubview(crosshairView)
        view.addSubview(colorPillView)
        view.addSubview(filterStrip)

        view.addSubview(missionPill)
        missionPill.addSubview(missionIcon)
        missionPill.addSubview(missionLabel)

        view.addSubview(thumbnailButton)
        view.addSubview(shutterButton)
        view.addSubview(flipButton)
        view.addSubview(countdownLabel)
        view.addSubview(focusSquareView)

        setupGestures()
        requestPermissionAndSetup()
    }

    private func setupGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFocusTap(_:)))
        previewView.addGestureRecognizer(tap)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            currentZoomFactor = viewModel.currentZoomFactor
        }
        let factor = currentZoomFactor * (gesture.scale)
        viewModel.setZoom(factor: factor)
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        previewView.snp.makeConstraints { $0.edges.equalToSuperview() }
        gridView.snp.makeConstraints { $0.edges.equalTo(previewView) }

        navBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
        navTitleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        gridButton.snp.makeConstraints {
            $0.trailing.equalTo(navTitleLabel.snp.leading).offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }
        timerButton.snp.makeConstraints {
            $0.leading.equalTo(navTitleLabel.snp.trailing).offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }
        timerLabel.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview()
        }
        doneButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        countdownLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        // Viewfinder
        crosshairView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(100)
        }
        colorPillView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(crosshairView.snp.bottom).offset(20)
            $0.height.equalTo(38)
        }

        // Bottom: shutter centered, thumbnail left, flip right
        shutterButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(28)
            $0.width.height.equalTo(72)
        }
        thumbnailButton.snp.makeConstraints {
            $0.centerY.equalTo(shutterButton)
            $0.trailing.equalTo(shutterButton.snp.leading).offset(-32)
            $0.width.height.equalTo(48)
        }
        flipButton.snp.makeConstraints {
            $0.centerY.equalTo(shutterButton)
            $0.leading.equalTo(shutterButton.snp.trailing).offset(32)
            $0.width.height.equalTo(48)
        }

        // Mission pill
        missionPill.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(shutterButton.snp.top).offset(-24)
            $0.height.equalTo(39)
        }
        missionIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(16)
        }
        missionLabel.snp.makeConstraints {
            $0.leading.equalTo(missionIcon.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        // Filter strip above mission pill
        filterStrip.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(missionPill.snp.top).offset(-14)
            $0.height.equalTo(36)
        }
    }

    // MARK: - bind

    override func bind() {
        // Navigation: 홈 탭으로 복귀 + 탭바 복구
        let exitAction: () -> Void = { [weak self] in
            self?.tabBarController?.tabBar.isHidden = false
            self?.tabBarController?.selectedIndex = 0
        }

        backButton.rx.tap
            .subscribe(onNext: { exitAction() })
            .disposed(by: disposeBag)

        // Done 버튼 (MrN1v 교체) — 카메라 종료
        doneButton.rx.tap
            .subscribe(onNext: { exitAction() })
            .disposed(by: disposeBag)

        gridButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.gridView.isHidden.toggle()
                self?.gridButton.tintColor = (self?.gridView.isHidden ?? true) ? .white : UIColor(hex: "#34D399")
            })
            .disposed(by: disposeBag)

        timerButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self, !self.isCountingDown else { return }
                if self.timerSeconds == 0 { self.timerSeconds = 3 }
                else if self.timerSeconds == 3 { self.timerSeconds = 5 }
                else if self.timerSeconds == 5 { self.timerSeconds = 10 }
                else { self.timerSeconds = 0 }
            })
            .disposed(by: disposeBag)

        // 갤러리 버튼 (gJyRv) — 사진 가져오기
        thumbnailButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.openPhotoPicker() })
            .disposed(by: disposeBag)

        flipButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.viewModel.flipCamera() })
            .disposed(by: disposeBag)

        shutterButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.handleShutterTap() })
            .disposed(by: disposeBag)

        // Filter selection
        filterStrip.selectedFilter
            .subscribe(onNext: { [weak self] f in self?.viewModel.setFilter(f) })
            .disposed(by: disposeBag)

        // Preview frames
        viewModel.previewImage
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] img in self?.previewView.image = img })
            .disposed(by: disposeBag)

        // Color pill & Dynamic Island 업데이트
        Observable.combineLatest(
            viewModel.detectedColor,
            viewModel.matchPercent,
            viewModel.missionColor
        )
        .throttle(.milliseconds(100), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] detectedColor, match, missionColor in
            guard let self else { return }
            
            // 중앙 알약: 고정 미션 색상(점), 고정 미션 헥스(텍스트), 실시간 일치율
            self.colorPillView.update(
                missionColor: missionColor,
                missionHex:   missionColor.toHexString(),
                match:        match
            )
            
           // TODO: Throttle/Debounce 고려
            
        })
        .disposed(by: disposeBag)

        // Dynamic Island 전용 throttle (1초)
        viewModel.matchPercent
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { match in
                guard #available(iOS 16.1, *) else { return }
                ColorActivityManager.shared.update(match: match)
            })
            .disposed(by: disposeBag)

        // Mission label
        viewModel.missionName
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] name in
                self?.missionLabel.text = L10n.cameraMissionLabel(name)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        viewModel.startSession()
        startDynamicIsland()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        viewModel.stopSession()
        if #available(iOS 16.1, *), !ColorActivityManager.shared.isTimedSessionActive {
            ColorActivityManager.shared.stop()
        }
    }

    // MARK: - Camera Permission

    private func requestPermissionAndSetup() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else { return }
            self?.viewModel.setupSession()
        }
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - Shutter Animation

    private func handleShutterTap() {
        guard timerSeconds > 0 else {
            animateShutter()
            return
        }

        isCountingDown = true
        shutterButton.isEnabled = false
        var count = timerSeconds
        countdownLabel.text = "\(count)"
        countdownLabel.isHidden = false
        countdownLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            count -= 1
            if count > 0 {
                self.countdownLabel.text = "\(count)"
                self.countdownLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                UIView.animate(withDuration: 0.2) {
                    self.countdownLabel.transform = .identity
                }
            } else {
                timer.invalidate()
                self.isCountingDown = false
                self.countdownLabel.isHidden = true
                self.shutterButton.isEnabled = true
                self.animateShutter()
            }
        }

        UIView.animate(withDuration: 0.2) {
            self.countdownLabel.transform = .identity
        }
    }

    private func animateShutter() {
        let flash = UIView(frame: view.bounds)
        flash.backgroundColor = .white
        flash.alpha = 0
        view.addSubview(flash)
        UIView.animate(withDuration: 0.08, animations: { flash.alpha = 0.85 }) { _ in
            UIView.animate(withDuration: 0.15, animations: { flash.alpha = 0 }) { _ in
                flash.removeFromSuperview()
                self.captureAndSave()
            }
        }
    }

    private func captureAndSave() {
        guard let img = previewView.image else { return }
        thumbnailButton.setImage(img, for: .normal)
        thumbnailButton.imageView?.contentMode = .scaleAspectFill

        let match = viewModel.matchPercent.value
        let location = locationManager.location?.coordinate
        let latitude = location?.latitude ?? 0.0
        let longitude = location?.longitude ?? 0.0

        // 1. 역지오코딩을 통해 주소 텍스트 가져오기
        fetchAddress(lat: latitude, lon: longitude) { [weak self] address in
            guard let self = self else { return }
            
            let isSuccess = match >= 60
            AnalyticsManager.shared.logPhotoCaptured(
                matchPercent: match,
                filter: self.viewModel.currentFilter.value.rawValue,
                isSuccess: isSuccess
            )

            if isSuccess {
                let card = ColorCard(
                    id: UUID().uuidString,
                    imageURL: nil,
                    capturedImage: img,
                    colorName: self.viewModel.missionName.value,
                    hexColor: self.viewModel.detectedHex.value,
                    dotColor: self.viewModel.detectedColor.value,
                    locationName: address,
                    captureDate: Self.currentDateString(),
                    matchPercentage: match,
                    missionCurrent: 0,
                    missionTotal: GridLayoutStore.shared.selectedLayout.value.slotCount,
                    latitude: latitude,
                    longitude: longitude
                )
                ColorCardStore.shared.add(card)
                self.showCaptureToast(success: true, match: match)
            } else {
                self.showCaptureToast(success: false, match: match)
            }
        }
    }

    private func fetchAddress(lat: Double, lon: Double, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "ko_KR")
        let location = CLLocation(latitude: lat, longitude: lon)
        
        geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, _ in
            if let pm = placemarks?.first {
                let locality = pm.locality ?? "" // 예: 강남구
                let subLocality = pm.subLocality ?? "" // 예: 역삼동
                let address = locality.isEmpty ? L10n.locationCurrent : "\(locality) \(subLocality)"
                completion(address)
            } else {
                completion(L10n.locationCurrent)
            }
        }
    }

    private func showCaptureToast(success: Bool, match: Int) {
        let toast = UIView()
        toast.backgroundColor = (success
            ? UIColor(hex: "#1A1A1A")
            : UIColor(hex: "#FF3B30")
        ).withAlphaComponent(0.88)
        toast.layer.cornerRadius = 20
        view.addSubview(toast)

        let label = UILabel()
        label.text = success
            ? L10n.cameraToastCollectSuccess(match)
            : L10n.cameraToastCollectFail(match)
        label.font = UIFont(name: "Pretendard-SemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        toast.addSubview(label)
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20))
        }
        toast.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(shutterButton.snp.top).offset(-24)
        }
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 8)

        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
            toast.transform = .identity
        }
        UIView.animate(withDuration: 0.3, delay: 1.8) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

    private static func currentDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt.string(from: Date())
    }

    // MARK: - Dynamic Island

    private func startDynamicIsland() {
        guard #available(iOS 16.1, *) else { return }
        let missionColor = viewModel.missionColor.value

        ColorActivityManager.shared.start(
            missionName: viewModel.missionName.value,
            missionHex:  missionColor.toHexString(),
            missionColor: missionColor,
            match: viewModel.matchPercent.value
        )
    }


    // MARK: - Gallery (gJyRv)

    private func openPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Focus

    private enum FocusConstants {
        static let animDuration: TimeInterval  = 0.2
        static let fadeDelay: TimeInterval     = 1.2
        static let fadeDuration: TimeInterval  = 0.4
        static let initialScale: CGFloat       = 1.3
    }

    @objc private func handleFocusTap(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: previewView)
        let normalizedX = tapPoint.x / previewView.bounds.width
        let normalizedY = tapPoint.y / previewView.bounds.height
        let adjustedX = viewModel.isFrontCamera ? 1 - normalizedX : normalizedX
        viewModel.setFocusPoint(CGPoint(x: adjustedX, y: normalizedY))
        showFocusIndicator(at: tapPoint)
    }

    private func showFocusIndicator(at point: CGPoint) {
        focusSquareView.layer.removeAllAnimations()
        focusSquareView.center = point
        focusSquareView.alpha = 1
        focusSquareView.transform = CGAffineTransform(scaleX: FocusConstants.initialScale, y: FocusConstants.initialScale)

        UIView.animate(withDuration: FocusConstants.animDuration) { [weak self] in
            self?.focusSquareView.transform = .identity
        } completion: { [weak self] _ in
            UIView.animate(
                withDuration: FocusConstants.fadeDuration,
                delay: FocusConstants.fadeDelay
            ) { [weak self] in
                self?.focusSquareView.alpha = 0
            }
        }
    }

}

// MARK: - PHPickerViewControllerDelegate

extension CameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        AnalyticsManager.shared.logGalleryImageUsed()

        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
            guard let self else { return }

            let exifCoordinate = data.flatMap { Self.extractGPSCoordinate(from: $0) }

            guard let image = data.flatMap({ UIImage(data: $0) }) else { return }
            DispatchQueue.main.async {
                let coordinate = exifCoordinate ?? self.locationManager.location?.coordinate
                let galleryVC = GalleryColorViewController(
                    image: image,
                    missionName: self.viewModel.missionName.value,
                    missionColor: self.viewModel.missionColor.value,
                    missionHex:   self.viewModel.detectedHex.value,
                    latitude: coordinate?.latitude ?? 0.0,
                    longitude: coordinate?.longitude ?? 0.0
                )
                self.present(galleryVC, animated: true)
            }
        }
    }

    private static func extractGPSCoordinate(from data: Data) -> CLLocationCoordinate2D? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let props  = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
            let gps    = props[kCGImagePropertyGPSDictionary as String] as? [String: Any],
            let lat    = gps[kCGImagePropertyGPSLatitude as String] as? Double,
            let lon    = gps[kCGImagePropertyGPSLongitude as String] as? Double
        else { return nil }

        let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
        let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"
        return CLLocationCoordinate2D(
            latitude:  latRef == "S" ? -lat : lat,
            longitude: lonRef == "W" ? -lon : lon
        )
    }
}

// MARK: - CLLocationManagerDelegate

extension CameraViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
