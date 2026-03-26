
//
//  GalleryColorViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class GalleryColorViewController: UIViewController {

    // MARK: - Properties
    private let image: UIImage
    private let missionColor: UIColor
    private let missionHex: String
    private let disposeBag = DisposeBag()

    private var tapIndicator: UIView?
    private var popupOverlay: UIView?

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
        l.text = "색상 수집"
        l.font = UIFont(name: "Pretendard-Bold", size: 17) ?? .boldSystemFont(ofSize: 17)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "원하는 색상 부분을 탭하세요"
        l.font = UIFont(name: "Pretendard-Medium", size: 13)
        l.textColor = UIColor.white.withAlphaComponent(0.65)
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init
    init(image: UIImage, missionColor: UIColor, missionHex: String) {
        self.image = image
        self.missionColor = missionColor
        self.missionHex = missionHex
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

        view.addSubview(hintLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.addGestureRecognizer(tap)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

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
        navTitleLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        hintLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(36)
        }
    }

    private func bind() {
        backButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismiss(animated: true) })
            .disposed(by: disposeBag)
    }

    // MARK: - Image Tap
    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: imageView)
        guard let color = colorAt(point: point, in: imageView) else { return }

        showTapIndicator(at: point, color: color)

        let match = colorMatch(detected: color)
        let hex = hexString(from: color)
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
        popup.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(320)
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

        // Spring animation
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
        let card = ColorCard(
            id: UUID().uuidString,
            imageURL: nil,
            capturedImage: image,
            colorName: hex,
            hexColor: hex,
            dotColor: color,
            locationName: "갤러리",
            captureDate: Self.currentDateString(),
            matchPercentage: match,
            missionCurrent: 0,
            missionTotal: 9
        )
        ColorCardStore.shared.add(card)

        let toast = UIView()
        toast.backgroundColor = UIColor(hex: "#1A1A1A").withAlphaComponent(0.85)
        toast.layer.cornerRadius = 20
        view.addSubview(toast)

        let label = UILabel()
        label.text = "✓  색상 수집 완료! (\(match)%)"
        label.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        label.textColor = .white
        toast.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)) }

        toast.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(80)
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

    // TODO: DateFormatterManager로 이동 필요
    private static func currentDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy.MM.dd"
        return fmt.string(from: Date())
    }

    // MARK: - Color Helpers
    private func colorAt(point: CGPoint, in imageView: UIImageView) -> UIColor? {
        guard let image = imageView.image,
              let cgImage = image.cgImage else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let viewSize = imageView.bounds.size

        // scaleAspectFit: scale to fit, centered
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

    private func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
