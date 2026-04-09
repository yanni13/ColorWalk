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

final class ColorDetailViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: ColorDetailViewModel
    private let swipeLeftSubject  = PublishSubject<Void>()
    private let swipeRightSubject = PublishSubject<Void>()

    private enum SwipeDirection { case left, right, none }
    private var pendingSwipeDirection: SwipeDirection = .none

    // MARK: - UI: Background
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
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

    // MARK: - UI: Swipe Hint
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - setupViews

    override func setupViews() {
        view.backgroundColor = .black

        pageCounterView.addSubview(pageCounterGlass)
        pageCounterView.addSubview(pageCounterLabel)

        [backgroundImageView, gradientOverlayView,
         backButton, shareButton, pageCounterView,
         colorNameRow, hexCodeLabel, metaLabel,
         swipeLeftChevron, swipeRightChevron].forEach { view.addSubview($0) }

        setupGesture()
        setupChevronTaps()
    }

    // MARK: - setupConstraints

    override func setupConstraints() {
        backgroundImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        gradientOverlayView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Top controls
        backButton.snp.makeConstraints {
            $0.width.height.equalTo(44)
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
        }
        shareButton.snp.makeConstraints {
            $0.width.height.equalTo(44)
            $0.trailing.equalToSuperview().inset(20)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
        }
        pageCounterView.snp.makeConstraints {
            $0.width.equalTo(66)
            $0.height.equalTo(28)
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(backButton)
        }
        pageCounterGlass.snp.makeConstraints { $0.edges.equalToSuperview() }
        pageCounterLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Bottom info
        colorNameRow.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.bottom.equalToSuperview().inset(182)
        }

        hexCodeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(colorNameRow.snp.bottom).offset(4)
        }
        metaLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(hexCodeLabel.snp.bottom).offset(8)
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

    // MARK: - Gesture

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

        if translation.x < -60 || velocity.x < -400 {
            pendingSwipeDirection = .left
            swipeLeftSubject.onNext(())
        } else if translation.x > 60 || velocity.x > 400 {
            pendingSwipeDirection = .right
            swipeRightSubject.onNext(())
        }
    }

    // MARK: - Share

    private func presentShareSheet(for card: ColorCard) {
        // 1. UI 컨트롤 일시 숨김 (렌더링 시 제거, 각 뷰의 원래 alpha 보존)
        let controls: [UIView] = [backButton, shareButton, pageCounterView, swipeLeftChevron, swipeRightChevron]
        let originalAlphas = controls.map { $0.alpha }
        controls.forEach { $0.alpha = 0 }

        // 2. 렌더링할 임시 뷰 생성
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }

        // 3. UI 컨트롤 복구 (원래 alpha 값으로 복원)
        zip(controls, originalAlphas).forEach { view, alpha in view.alpha = alpha }

        // 4. GPS 포함 저장 액티비티 구성 (좌표가 유효한 경우에만)
        let coordinate = CLLocationCoordinate2D(latitude: card.latitude, longitude: card.longitude)
        var applicationActivities: [UIActivity] = []
        if card.latitude != 0 || card.longitude != 0,
           let gpsData = ImageFileManager.shared.jpegDataWithGPS(from: image, coordinate: coordinate) {
            let saveActivity = SaveToPhotosWithGPSActivity(imageData: gpsData, coordinate: coordinate)
            applicationActivities.append(saveActivity)
        }

        // 5. 공유 항목 및 메타데이터 구성 (Thumbnail 표시 포함)
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
