
//
//  ColorPickerSheetViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ColorPickerSheetViewController: UIViewController {

    // MARK: - Types
    struct PresetColor {
        let name: String
        let hex: String
        let color: UIColor
    }

    static var presets: [PresetColor] {
        [
            PresetColor(name: L10n.colorPresetSky,          hex: "#5B8DEF", color: UIColor(hex: "#5B8DEF")),
            PresetColor(name: L10n.colorPresetCherryBlossom, hex: "#FF7EB3", color: UIColor(hex: "#FF7EB3")),
            PresetColor(name: L10n.colorPresetLavender,     hex: "#9B7DFF", color: UIColor(hex: "#9B7DFF")),
            PresetColor(name: L10n.colorPresetSunset,       hex: "#FFB347", color: UIColor(hex: "#FFB347")),
            PresetColor(name: L10n.colorPresetMint,         hex: "#34D399", color: UIColor(hex: "#34D399")),
            PresetColor(name: L10n.colorPresetCoral,        hex: "#F87171", color: UIColor(hex: "#F87171")),
            PresetColor(name: L10n.colorPresetOcean,        hex: "#60A5FA", color: UIColor(hex: "#60A5FA")),
            PresetColor(name: L10n.colorPresetGrape,        hex: "#A78BFA", color: UIColor(hex: "#A78BFA"))
        ]
    }

    // MARK: - Properties
    private let currentMission: ColorMission
    var onApply: ((UIColor, String, String) -> Void)?

    private let disposeBag = DisposeBag()
    private let selectedRelay: BehaviorRelay<(UIColor, String, String)>
    private var selectedPresetIndex: Int? = nil

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
        v.backgroundColor = UIColor(hex: "#D1D5DB")
        v.layer.cornerRadius = 2
        return v
    }()

    // MARK: - UI: Header
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.colorPickerTitle
        l.font = UIFont(name: "Pretendard-Bold", size: 20)
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

    // MARK: - UI: Current Color
    private let currentDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        return v
    }()

    private let currentTopLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.colorPickerCurrentColorLabel
        l.font = UIFont(name: "Pretendard-Medium", size: 11)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private let currentBottomLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private lazy var currentInfoStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [currentTopLabel, currentBottomLabel])
        s.axis = .vertical
        s.spacing = 2
        return s
    }()

    private let currentColorRow: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F8F9FA")
        v.layer.cornerRadius = 16
        return v
    }()

    // MARK: - UI: Preset Section
    private let presetLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.colorPickerPresetLabel
        l.font = UIFont(name: "Pretendard-Bold", size: 14)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let presetStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .equalSpacing
        s.alignment = .center
        return s
    }()

    private lazy var presetSection: UIStackView = {
        let s = UIStackView(arrangedSubviews: [presetLabel, presetStack])
        s.axis = .vertical
        s.spacing = 14
        return s
    }()

    // MARK: - UI: Action Row
    private let randomButton: UIButton = {
        let b = UIButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.background.backgroundColor = .white
        cfg.background.cornerRadius = 14
        cfg.background.strokeColor = UIColor(hex: "#E0E0E0")
        cfg.background.strokeWidth = 1
        cfg.imagePadding = 8
        cfg.image = UIImage(systemName: "shuffle", withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        cfg.baseForegroundColor = UIColor(hex: "#191F28")
        var t = AttributedString(L10n.buttonRandomColor)
        t.font = UIFont(name: "Pretendard-SemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        t.foregroundColor = UIColor(hex: "#191F28")
        cfg.attributedTitle = t
        b.configuration = cfg
        return b
    }()

    private let hexInputButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = .white
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
        return b
    }()

    private let hexHashLabel: UILabel = {
        let l = UILabel()
        l.text = "#"
        l.font = UIFont(name: "Pretendard-Bold", size: 16)
        l.textColor = UIColor(hex: "#B0B8C1")
        return l
    }()

    private let hexPlaceholderLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.colorPickerCustomInputLabel
        l.font = UIFont(name: "Pretendard-Regular", size: 14)
        l.textColor = UIColor(hex: "#B0B8C1")
        return l
    }()

    private let hexCircleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E0E0E0")
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(hex: "#D1D5DB").cgColor
        return v
    }()

    private lazy var actionRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [randomButton, hexInputButton])
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    // MARK: - UI: Apply
    private let applyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(L10n.buttonApply, for: .normal)
        b.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 16)
        b.tintColor = .white
        b.backgroundColor = UIColor(hex: "#1A1A1A")
        b.layer.cornerRadius = 14
        return b
    }()

    // MARK: - Init
    init(currentMission: ColorMission) {
        self.currentMission = currentMission
        self.selectedRelay = BehaviorRelay(value: (currentMission.color, currentMission.hexColor, currentMission.name))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        buildPresets()
        setupConstraints()
        bind()
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
        sheetView.addSubview(currentColorRow)
        currentColorRow.addSubview(currentDotView)
        currentColorRow.addSubview(currentInfoStack)
        sheetView.addSubview(presetSection)
        sheetView.addSubview(actionRow)
        hexInputButton.addSubview(hexHashLabel)
        hexInputButton.addSubview(hexPlaceholderLabel)
        hexInputButton.addSubview(hexCircleView)
        sheetView.addSubview(applyButton)

        currentDotView.backgroundColor = currentMission.color
        currentBottomLabel.text = "\(currentMission.name) · \(currentMission.hexColor)"

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:)))
        view.addGestureRecognizer(overlayTap)
    }

    private func buildPresets() {
        for (i, preset) in Self.presets.enumerated() {
            let colStack = UIStackView()
            colStack.axis = .vertical
            colStack.alignment = .center
            colStack.spacing = 6

            let dot = UIButton(type: .custom)
            dot.backgroundColor = preset.color
            dot.layer.cornerRadius = 20
            dot.tag = i
            dot.accessibilityLabel = preset.name
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(40)
            }
            dot.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)

            let lbl = UILabel()
            lbl.text = preset.name
            lbl.font = UIFont(name: "Pretendard-Regular", size: 10)
            lbl.textColor = UIColor(hex: "#6B7684")
            lbl.textAlignment = .center
            lbl.numberOfLines = 2
            lbl.lineBreakMode = .byWordWrapping
            lbl.snp.makeConstraints { make in
                make.width.equalTo(40)
            }

            colStack.addArrangedSubview(dot)
            colStack.addArrangedSubview(lbl)
            presetStack.addArrangedSubview(colStack)
        }
    }

    // MARK: - Constraints
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

        currentColorRow.snp.makeConstraints {
            $0.top.equalTo(headerRow.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(60)
        }

        currentDotView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        currentInfoStack.snp.makeConstraints {
            $0.leading.equalTo(currentDotView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        presetSection.snp.makeConstraints {
            $0.top.equalTo(currentColorRow.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        actionRow.snp.makeConstraints {
            $0.top.equalTo(presetSection.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(48)
        }

        hexHashLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
        }
        hexPlaceholderLabel.snp.makeConstraints {
            $0.leading.equalTo(hexHashLabel.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }
        hexCircleView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        applyButton.snp.makeConstraints {
            $0.top.equalTo(actionRow.snp.bottom).offset(20)
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

        selectedRelay
            .subscribe(onNext: { [weak self] (color, hex, name) in
                guard let self else { return }
                self.currentDotView.backgroundColor = color
                self.currentBottomLabel.text = "\(name) · \(hex)"
            })
            .disposed(by: disposeBag)

        randomButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.applyRandomColor()
            })
            .disposed(by: disposeBag)

        hexInputButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let palette = ColorPalettePickerSheetViewController()
                palette.modalPresentationStyle = .overFullScreen
                palette.onColorPicked = { [weak self] color, hex in
                    self?.selectedRelay.accept((color, hex, L10n.colorPickerCustomColorName))
                    self?.setHexInputDisplay(color: color, hex: hex)
                    self?.updatePresetRings(selectedIndex: nil)
                    self?.selectedPresetIndex = nil
                }
                self.present(palette, animated: false)
            })
            .disposed(by: disposeBag)

        applyButton.rx.tap
            .withLatestFrom(selectedRelay)
            .subscribe(onNext: { [weak self] (color, hex, name) in
                guard let self else { return }
                let confirm = ColorConfirmSheetViewController(
                    currentMission: self.currentMission,
                    selectedColor: color,
                    selectedHex: hex,
                    selectedName: name
                )
                confirm.modalPresentationStyle = .overFullScreen
                confirm.onApply = { [weak self] color, hex, name in
                    self?.onApply?(color, hex, name)
                }
                self.present(confirm, animated: false)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    @objc private func presetTapped(_ sender: UIButton) {
        applyPresetSelection(at: sender.tag)
    }

    @objc private func overlayTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: view)
        if !sheetView.frame.contains(loc) { dismissSheet() }
    }

    private func applyPresetSelection(at index: Int) {
        let preset = Self.presets[index]
        selectedPresetIndex = index
        selectedRelay.accept((preset.color, preset.hex, preset.name))
        updatePresetRings(selectedIndex: index)
        resetHexInputDisplay()
    }

    private func applyRandomColor() {
        let r = CGFloat.random(in: 0...1)
        let g = CGFloat.random(in: 0...1)
        let b = CGFloat.random(in: 0...1)
        let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
        let hex = String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
        
        selectedPresetIndex = nil
        selectedRelay.accept((color, hex, L10n.buttonRandomColor))
        updatePresetRings(selectedIndex: nil)
        resetHexInputDisplay()
    }

    private func updatePresetRings(selectedIndex: Int?) {
        for (i, view) in presetStack.arrangedSubviews.enumerated() {
            guard let stack = view as? UIStackView,
                  let btn = stack.arrangedSubviews.first as? UIButton else { continue }
            if i == selectedIndex {
                btn.layer.borderWidth = 3
                btn.layer.borderColor = Self.presets[i].color.withAlphaComponent(0.4).cgColor
            } else {
                btn.layer.borderWidth = 0
            }
        }
    }

    private func setHexInputDisplay(color: UIColor, hex: String) {
        hexHashLabel.textColor = UIColor(hex: "#191F28")
        hexPlaceholderLabel.text = String(hex.dropFirst())
        hexPlaceholderLabel.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        hexPlaceholderLabel.textColor = UIColor(hex: "#191F28")
        hexCircleView.backgroundColor = color
        hexCircleView.layer.borderColor = color.cgColor
        hexInputButton.layer.borderColor = UIColor(hex: "#1A1A1A").cgColor
        hexInputButton.layer.borderWidth = 1.5
    }

    private func resetHexInputDisplay() {
        hexHashLabel.textColor = UIColor(hex: "#B0B8C1")
        hexPlaceholderLabel.text = L10n.colorPickerCustomInputLabel
        hexPlaceholderLabel.font = UIFont(name: "Pretendard-Regular", size: 14)
        hexPlaceholderLabel.textColor = UIColor(hex: "#B0B8C1")
        hexCircleView.backgroundColor = UIColor(hex: "#E0E0E0")
        hexCircleView.layer.borderColor = UIColor(hex: "#D1D5DB").cgColor
        hexInputButton.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
        hexInputButton.layer.borderWidth = 1
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
