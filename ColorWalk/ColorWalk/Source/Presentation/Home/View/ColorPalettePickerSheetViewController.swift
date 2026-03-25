
//
//  ColorPalettePickerSheetViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ColorPalettePickerSheetViewController: UIViewController {

    // MARK: - Properties
    var onColorPicked: ((UIColor, String) -> Void)?

    private let disposeBag = DisposeBag()
    private var currentHue: CGFloat = 0.0
    private var currentSaturation: CGFloat = 1.0
    private var currentBrightness: CGFloat = 1.0

    // MARK: - UI: Sheet
    private let sheetView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: -4)
        v.layer.shadowRadius = 24
        v.layer.shadowOpacity = 0.15
        return v
    }()

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#DADCE0")
        v.layer.cornerRadius = 2
        return v
    }()

    // MARK: - UI: Header
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "색상 직접 선택"
        l.font = UIFont(name: "Pretendard-Bold", size: 18)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(
            UIImage(systemName: "xmark")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            ), for: .normal
        )
        b.tintColor = UIColor(hex: "#191F28")
        b.backgroundColor = .white
        b.layer.cornerRadius = 16
        return b
    }()

    private let headerRow = UIView()

    // MARK: - UI: Spectrum + Hue
    private let spectrumView = SpectrumView()
    private let hueBarView = HueBarView()

    // MARK: - UI: Preview Row
    private let previewCircle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        return v
    }()

    private let hexTextLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Bold", size: 16)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let pantoneLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 12)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var previewInfoStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [hexTextLabel, pantoneLabel])
        s.axis = .vertical
        s.spacing = 2
        return s
    }()

    private lazy var previewRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [previewCircle, previewInfoStack])
        s.axis = .horizontal
        s.spacing = 12
        s.alignment = .center
        return s
    }()

    // MARK: - UI: Apply
    private let applyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("적용하기", for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 16)
        b.tintColor = .white
        b.backgroundColor = UIColor(hex: "#1A1A1A")
        b.layer.cornerRadius = 14
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bind()
        updatePreview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .clear
        view.layoutIfNeeded()
        sheetView.transform = CGAffineTransform(translationX: 0, y: sheetView.frame.height)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.sheetView.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(sheetView)
        sheetView.addSubview(handleView)
        sheetView.addSubview(headerRow)
        headerRow.addSubview(titleLabel)
        headerRow.addSubview(closeButton)
        sheetView.addSubview(spectrumView)
        sheetView.addSubview(hueBarView)
        sheetView.addSubview(previewRow)
        sheetView.addSubview(applyButton)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:)))
        view.addGestureRecognizer(overlayTap)

        spectrumView.layer.cornerRadius = 12
        spectrumView.layer.masksToBounds = true
    }

    private func setupConstraints() {
        sheetView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(4)
        }

        headerRow.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        closeButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        spectrumView.snp.makeConstraints {
            $0.top.equalTo(headerRow.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(200)
        }

        hueBarView.snp.makeConstraints {
            $0.top.equalTo(spectrumView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(24)
        }

        previewCircle.snp.makeConstraints { $0.width.height.equalTo(40) }

        previewRow.snp.makeConstraints {
            $0.top.equalTo(hueBarView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        applyButton.snp.makeConstraints {
            $0.top.equalTo(previewRow.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(52)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }

    // MARK: - Bind
    private func bind() {
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismissSheet() })
            .disposed(by: disposeBag)

        spectrumView.onColorChanged = { [weak self] saturation, brightness in
            self?.currentSaturation = saturation
            self?.currentBrightness = brightness
            self?.updatePreview()
        }

        hueBarView.onHueChanged = { [weak self] hue in
            self?.currentHue = hue
            self?.spectrumView.hue = hue
            self?.updatePreview()
        }

        applyButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let color = self.currentColor()
                let hex = self.hexString(from: color)
                self.onColorPicked?(color, hex)
                self.dismissSheet()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Color Helpers
    private func currentColor() -> UIColor {
        UIColor(hue: currentHue,
                saturation: currentSaturation,
                brightness: max(0.01, currentBrightness),
                alpha: 1)
    }

    private func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private func updatePreview() {
        let color = currentColor()
        let hex = hexString(from: color)
        previewCircle.backgroundColor = color
        hexTextLabel.text = hex
        pantoneLabel.text = "선택된 색상"
    }

    // MARK: - Actions
    @objc private func overlayTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: view)
        if !sheetView.frame.contains(loc) { dismissSheet() }
    }

    // MARK: - Dismiss
    func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.sheetView.frame.height)
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
}
