
//
//  GalleryColorViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import CoreLocation
import Vision

final class GalleryColorViewController: UIViewController {

    // MARK: - Properties
    private let image: UIImage
    private let missionName: String
    private let missionColor: UIColor
    private let missionHex: String
    private let latitude: Double
    private let longitude: Double
    private let disposeBag = DisposeBag()

    private var tapIndicator: UIView?
    private var popupOverlay: UIView?
    private var isExtracting = false

    private enum Constants {
        static let navBarHeight: CGFloat = 56
        static let buttonSize: CGFloat = 44
    }

    // MARK: - UI
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.isUserInteractionEnabled = true
        return iv
    }()

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
        l.text = L10n.galleryTitle
        l.font = UIFont(name: "Pretendard-Bold", size: 17) ?? .boldSystemFont(ofSize: 17)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let extractButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "sparkles")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
            for: .normal
        )
        b.tintColor = .white
        b.accessibilityLabel = "피사체 분리"
        return b
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = .white
        v.hidesWhenStopped = true
        return v
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.galleryInstruction
        l.font = UIFont(name: "Pretendard-Medium", size: 13)
        l.textColor = UIColor.white.withAlphaComponent(0.65)
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init
    init(image: UIImage, missionName: String, missionColor: UIColor, missionHex: String, latitude: Double = 0.0, longitude: Double = 0.0) {
        self.image = image
        self.missionName = missionName
        self.missionColor = missionColor
        self.missionHex = missionHex
        self.latitude = latitude
        self.longitude = longitude
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bind()
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .black
        view.addSubview(imageView)
        imageView.image = image

        view.addSubview(navBar)
        navBar.addSubview(backButton)
        navBar.addSubview(navTitleLabel)
        navBar.addSubview(extractButton)
        navBar.addSubview(loadingIndicator)

        view.addSubview(hintLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.addGestureRecognizer(tap)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        navBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.navBarHeight)
        }
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Constants.buttonSize)
        }
        navTitleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        extractButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Constants.buttonSize)
        }
        loadingIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(30)
            make.centerY.equalToSuperview()
        }

        hintLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(36)
        }
    }

    private func bind() {
        backButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismiss(animated: true) })
            .disposed(by: disposeBag)

        extractButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.handleExtractTap() })
            .disposed(by: disposeBag)
    }

    // MARK: - Image Tap
    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: imageView)
        guard let color = colorAt(point: point, in: imageView) else { return }

        showTapIndicator(at: point, color: color)

        let match = colorMatch(detected: color)
        let hex = color.toHexString()
        showPopup(color: color, hex: hex, match: match)
    }

    // MARK: - Tap Indicator
    private func showTapIndicator(at point: CGPoint, color: UIColor) {
        tapIndicator?.removeFromSuperview()

        let ring = UIView()
        ring.frame = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
        ring.layer.cornerRadius = 15
        ring.backgroundColor = color
        ring.layer.borderWidth = 3
        ring.layer.borderColor = UIColor.white.cgColor
        ring.layer.shadowColor = UIColor.black.cgColor
        ring.layer.shadowOffset = .zero
        ring.layer.shadowRadius = 6
        ring.layer.shadowOpacity = 0.4
        ring.isUserInteractionEnabled = false
        imageView.addSubview(ring)
        tapIndicator = ring

        ring.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        ring.alpha = 0
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0) {
            ring.transform = .identity
            ring.alpha = 1
        }
    }

    // MARK: - Popup
    private func showPopup(color: UIColor, hex: String, match: Int) {
        popupOverlay?.removeFromSuperview()

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.addSubview(overlay)
        popupOverlay = overlay

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        overlay.addGestureRecognizer(tap)

        let popup = GalleryColorPopupView()
        popup.configure(color: color, hex: hex, match: match)
        overlay.addSubview(popup)
        popup.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(320)
        }
        popup.isUserInteractionEnabled = true

        popup.onRetry = { [weak self] in
            self?.dismissPopupAnimated()
        }
        popup.onCollect = { [weak self] in
            guard match >= 60 else { return }
            self?.dismissPopupAnimated { [weak self] in
                self?.showCollectSuccess(color: color, hex: hex, match: match)
            }
        }

        overlay.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0) {
            overlay.alpha = 1
            popup.transform = .identity
        }
    }

    @objc private func dismissPopup() {
        dismissPopupAnimated()
    }

    private func dismissPopupAnimated(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.popupOverlay?.alpha = 0
        }) { _ in
            self.popupOverlay?.removeFromSuperview()
            self.popupOverlay = nil
            completion?()
        }
    }

    // MARK: - Collect Success
    private func showCollectSuccess(color: UIColor, hex: String, match: Int) {
        fetchAddress(lat: latitude, lon: longitude) { [weak self] address in
            guard let self else { return }
            let card = ColorCard(
                id: UUID().uuidString,
                imageURL: nil,
                capturedImage: self.image,
                colorName: self.missionName,
                hexColor: hex,
                dotColor: color,
                locationName: address,
                captureDate: Self.currentDateString(),
                matchPercentage: match,
                missionCurrent: 0,
                missionTotal: GridLayoutStore.shared.selectedLayout.value.slotCount,
                latitude: self.latitude,
                longitude: self.longitude
            )
            ColorCardStore.shared.add(card)
            self.showCollectToast(match: match)
        }
    }

    private func fetchAddress(lat: Double, lon: Double, completion: @escaping (String) -> Void) {
        guard lat != 0.0 || lon != 0.0 else {
            completion(L10n.locationCurrent)
            return
        }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(
            CLLocation(latitude: lat, longitude: lon),
            preferredLocale: Locale(identifier: "ko_KR")
        ) { placemarks, _ in
            if let pm = placemarks?.first {
                let locality    = pm.locality ?? ""
                let subLocality = pm.subLocality ?? ""
                completion(locality.isEmpty ? L10n.locationCurrent : "\(locality) \(subLocality)")
            } else {
                completion(L10n.locationCurrent)
            }
        }
    }

    private func showCollectToast(match: Int) {
        let toast = UIView()
        toast.backgroundColor = UIColor(hex: "#1A1A1A").withAlphaComponent(0.85)
        toast.layer.cornerRadius = 20
        view.addSubview(toast)

        let label = UILabel()
        label.text = L10n.cameraToastCollectSuccess(match)
        label.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        label.textColor = .white
        toast.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20))
        }
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(80)
        }
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 10)

        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
            toast.transform = .identity
        }
        UIView.animate(withDuration: 0.3, delay: 1.8) {
            toast.alpha = 0
        } completion: { [weak self] _ in
            toast.removeFromSuperview()
            self?.dismiss(animated: true)
        }
    }

    // MARK: - Subject Extraction

    private func handleExtractTap() {
        guard !isExtracting else { return }
        isExtracting = true
        extractButton.isHidden = true
        loadingIndicator.startAnimating()

        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let extracted = try await self.extractSubject(from: self.image)
                await MainActor.run {
                    self.finishExtraction(with: extracted)
                }
            } catch {
                await MainActor.run {
                    self.cancelExtraction()
                }
            }
        }
    }

    private func finishExtraction(with extractedImage: UIImage) {
        isExtracting = false
        extractButton.isHidden = false
        loadingIndicator.stopAnimating()

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        let sheet = StickerExtractSheetViewController(
            stickerImage: extractedImage,
            colorName: missionName,
            hexColor: missionHex
        )
        sheet.onSave = { [weak self] in
            guard let self else { return }
            _ = StickerManager.shared.save(image: extractedImage, colorName: self.missionName, hex: self.missionHex)
            self.showStickerSavedToast()
        }
        sheet.onCopy = {
            UIPasteboard.general.image = extractedImage
        }
        sheet.onShare = { [weak self] in
            guard let self else { return }
            let activity = UIActivityViewController(activityItems: [extractedImage], applicationActivities: nil)
            self.present(activity, animated: true)
        }
        present(sheet, animated: false)
    }

    private func cancelExtraction() {
        isExtracting = false
        extractButton.isHidden = false
        loadingIndicator.stopAnimating()

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.error)
        showExtractionFailToast()
    }

    private func extractSubject(from image: UIImage) async throws -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let oriented = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        guard let cgImage = oriented.cgImage else {
            throw GalleryExtractionError.invalidImage
        }
        let ciImage = CIImage(cgImage: cgImage)
        let downsampled = ciImage.transformed(by: CGAffineTransform(scaleX: 0.5, y: 0.5))
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: downsampled)
        try handler.perform([request])
        guard let result = request.results?.first else {
            throw GalleryExtractionError.noSubjectFound
        }
        let allInstances = result.allInstances
        guard !allInstances.isEmpty else {
            throw GalleryExtractionError.noSubjectFound
        }
        let maskBuffer = try result.generateScaledMaskForImage(
            forInstances: allInstances,
            from: handler
        )
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let masked = downsampled.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: maskImage,
            kCIInputBackgroundImageKey: CIImage.empty()
        ])
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let resultCGImage = context.createCGImage(masked, from: masked.extent) else {
            throw GalleryExtractionError.renderFailed
        }
        return UIImage(cgImage: resultCGImage)
    }

    private func showStickerSavedToast() {
        showToast(message: "스티커 보관함에 저장되었습니다")
    }

    private func showExtractionFailToast() {
        showToast(message: "피사체를 찾을 수 없습니다")
    }

    private func showToast(message: String) {
        let toast = UIView()
        toast.backgroundColor = UIColor(hex: "#1A1A1A").withAlphaComponent(0.85)
        toast.layer.cornerRadius = 20
        view.addSubview(toast)

        let label = UILabel()
        label.text = message
        label.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        label.textColor = .white
        toast.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20))
        }
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(80)
        }
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 10)

        UIView.animate(withDuration: 0.3) {
            toast.alpha = 1
            toast.transform = .identity
        }
        UIView.animate(withDuration: 0.3, delay: 2.0) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

    // MARK: - Helpers

    private static func currentDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt.string(from: Date())
    }

    private func colorAt(point: CGPoint, in imageView: UIImageView) -> UIColor? {
        guard let image = imageView.image,
              let cgImage = image.cgImage else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let viewSize = imageView.bounds.size

        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        let scale = min(scaleX, scaleY)

        let scaledW = imageSize.width * scale
        let scaledH = imageSize.height * scale
        let offsetX = (viewSize.width - scaledW) / 2
        let offsetY = (viewSize.height - scaledH) / 2

        let imgX = (point.x - offsetX) / scale
        let imgY = (point.y - offsetY) / scale

        guard imgX >= 0, imgX < imageSize.width,
              imgY >= 0, imgY < imageSize.height else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: &pixel, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else { return nil }

        ctx.translateBy(x: -imgX, y: -imgY)
        ctx.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))

        return UIColor(
            red:   CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue:  CGFloat(pixel[2]) / 255,
            alpha: 1
        )
    }

    private func colorMatch(detected: UIColor) -> Int {
        var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0
        var mr: CGFloat = 0, mg: CGFloat = 0, mb: CGFloat = 0
        detected.getRed(&dr, green: &dg, blue: &db, alpha: nil)
        missionColor.getRed(&mr, green: &mg, blue: &mb, alpha: nil)
        let dist = sqrt(pow(dr - mr, 2) + pow(dg - mg, 2) + pow(db - mb, 2))
        return max(0, min(100, Int((1 - dist / sqrt(3)) * 100)))
    }
}

// MARK: - GalleryExtractionError

private enum GalleryExtractionError: Error {
    case invalidImage
    case noSubjectFound
    case renderFailed
}
