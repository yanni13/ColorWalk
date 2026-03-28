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

final class CameraViewController: BaseViewController {

    // MARK: - Callbacks
    var onBack: (() -> Void)?

    // MARK: - ViewModel
    private let viewModel = CameraViewModel()
    private let locationManager = CLLocationManager()

    // MARK: - Preview
    private let previewView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .black
        return iv
    }()

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
        l.text = "색상 촬영"
        l.font = UIFont(name: "Pretendard-Bold", size: 17) ?? .boldSystemFont(ofSize: 17)
        l.textColor = .white
        l.textAlignment = .center
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
        l.text = "오늘의 미션: Sky Blue를 찾아보세요"
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
        view.addSubview(navBar)
        navBar.addSubview(backButton)
        navBar.addSubview(navTitleLabel)
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

        requestPermissionAndSetup()
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        previewView.snp.makeConstraints { $0.edges.equalToSuperview() }

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
        doneButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
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

        // 갤러리 버튼 (gJyRv) — 사진 가져오기
        thumbnailButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.openPhotoPicker() })
            .disposed(by: disposeBag)

        flipButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.viewModel.flipCamera() })
            .disposed(by: disposeBag)

        shutterButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.animateShutter() })
            .disposed(by: disposeBag)

        // Filter selection
        filterStrip.selectedFilter
            .subscribe(onNext: { [weak self] f in self?.viewModel.setFilter(f) })
            .disposed(by: disposeBag)

        // Preview frames
        viewModel.previewImage
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] img in self?.previewView.image = img })
            .disposed(by: disposeBag)

        // Color pill & Dynamic Island 업데이트
        Observable.combineLatest(
            viewModel.detectedColor,
            viewModel.matchPercent,
            viewModel.missionColor,
            ColorCardStore.shared.cards
        )
        .throttle(.milliseconds(100), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] detectedColor, match, missionColor, cards in
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
            .subscribe(onNext: { [weak self] name in
                self?.missionLabel.text = "오늘의 미션: \(name)를 찾아보세요"
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
            
            if match >= 60 {
                let card = ColorCard(
                    id: UUID().uuidString,
                    imageURL: nil,
                    capturedImage: img,
                    colorName: self.viewModel.missionName.value,
                    hexColor: self.viewModel.detectedHex.value,
                    dotColor: self.viewModel.detectedColor.value,
                    locationName: address, // 실제 주소 텍스트 삽입
                    captureDate: Self.currentDateString(),
                    matchPercentage: match,
                    missionCurrent: 0,
                    missionTotal: 9,
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
                let address = locality.isEmpty ? "현재 위치" : "\(locality) \(subLocality)"
                completion(address)
            } else {
                completion("현재 위치")
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
            ? "✓  색상 수집 완료! (\(match)%)"
            : "✗  일치율 \(match)% · 60% 이상이어야 수집 가능해요"
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

}

// MARK: - PHPickerViewControllerDelegate

extension CameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            DispatchQueue.main.async {
                guard let self, let image = obj as? UIImage else { return }
                let location = self.locationManager.location?.coordinate
                let galleryVC = GalleryColorViewController(
                    image: image,
                    missionName: self.viewModel.missionName.value,
                    missionColor: self.viewModel.missionColor.value,
                    missionHex:   self.viewModel.detectedHex.value,
                    latitude: location?.latitude ?? 0.0,
                    longitude: location?.longitude ?? 0.0
                )
                self.present(galleryVC, animated: true)
            }
        }
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
