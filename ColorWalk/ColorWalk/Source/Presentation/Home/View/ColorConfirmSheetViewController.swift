
//
//  ColorConfirmSheetViewController.swift
//  ColorWalk
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ColorConfirmSheetViewController: UIViewController {

    // MARK: - Properties
    private let currentMission: ColorMission
    private var pendingColor: UIColor
    private var pendingHex: String
    private var pendingName: String
    var onApply: ((UIColor, String, String) -> Void)?

    private let disposeBag = DisposeBag()

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
        l.text = "색상 변경 확인"
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

    // MARK: - UI: Color Compare
    private let compareView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#F8F9FA")
        v.layer.cornerRadius = 16
        return v
    }()

    // Old color row
    private let oldDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.alpha = 0.5
        return v
    }()

    private let oldTopLabel: UILabel = {
        let l = UILabel()
        l.text = "기존 색상"
        l.font = UIFont(name: "Pretendard-Medium", size: 10)
        l.textColor = UIColor(hex: "#B0B8C1")
        return l
    }()

    private let oldBottomLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-Regular", size: 13)
        l.textColor = UIColor(hex: "#6B7684")
        return l
    }()

    private lazy var oldInfoStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [oldTopLabel, oldBottomLabel])
        s.axis = .vertical
        s.spacing = 1
        return s
    }()

    private let oldRow = UIView()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E0E0E0")
        return v
    }()

    // New color row
    private let newDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18
        return v
    }()

    private let newTopLabel: UILabel = {
        let l = UILabel()
        l.text = "선택한 색상"
        l.font = UIFont(name: "Pretendard-Bold", size: 10)
        l.textColor = UIColor(hex: "#1A1A1A")
        return l
    }()

    private let newBottomLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private lazy var newInfoStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [newTopLabel, newBottomLabel])
        s.axis = .vertical
        s.spacing = 1
        return s
    }()

    private let newRow = UIView()

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
        var t = AttributedString("랜덤 색상")
        t.font = UIFont(name: "Pretendard-SemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        t.foregroundColor = UIColor(hex: "#191F28")
        cfg.attributedTitle = t
        b.configuration = cfg
        return b
    }()

    private let hexDisplayButton: UIButton = {
        let b = UIButton(type: .custom)
        b.backgroundColor = .white
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor(hex: "#1A1A1A").cgColor
        return b
    }()

    private let hexHashLabel: UILabel = {
        let l = UILabel()
        l.text = "#"
        l.font = UIFont(name: "Pretendard-Bold", size: 16)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let hexValueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        l.textColor = UIColor(hex: "#191F28")
        return l
    }()

    private let hexDotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        return v
    }()

    private lazy var actionRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [randomButton, hexDisplayButton])
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        return s
    }()

    // MARK: - UI: Tip Row
    private let tipIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "info.circle")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        )
        iv.tintColor = UIColor(hex: "#E07A5F")
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let tipLabel: UILabel = {
        let l = UILabel()
        l.text = "선택한 색상으로 오늘의 미션이 변경됩니다."
        l.font = UIFont(name: "Pretendard-Medium", size: 12)
        l.textColor = UIColor(hex: "#9B6B5A")
        l.numberOfLines = 0
        return l
    }()

    private let tipRow: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#FFF8F6")
        v.layer.cornerRadius = 12
        return v
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

    // MARK: - Init
    init(currentMission: ColorMission, selectedColor: UIColor, selectedHex: String, selectedName: String) {
        self.currentMission = currentMission
        self.pendingColor = selectedColor
        self.pendingHex = selectedHex
        self.pendingName = selectedName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureContent()
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

        sheetView.addSubview(compareView)
        compareView.addSubview(oldRow)
        oldRow.addSubview(oldDotView)
        oldRow.addSubview(oldInfoStack)
        compareView.addSubview(divider)
        compareView.addSubview(newRow)
        newRow.addSubview(newDotView)
        newRow.addSubview(newInfoStack)

        sheetView.addSubview(actionRow)
        hexDisplayButton.addSubview(hexHashLabel)
        hexDisplayButton.addSubview(hexValueLabel)
        hexDisplayButton.addSubview(hexDotView)

        sheetView.addSubview(tipRow)
        tipRow.addSubview(tipIconView)
        tipRow.addSubview(tipLabel)

        sheetView.addSubview(applyButton)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:)))
        view.addGestureRecognizer(overlayTap)
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

        // Compare
        compareView.snp.makeConstraints {
            $0.top.equalTo(headerRow.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        oldRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        oldDotView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.width.height.equalTo(28)
        }

        oldInfoStack.snp.makeConstraints {
            $0.leading.equalTo(oldDotView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        divider.snp.makeConstraints {
            $0.top.equalTo(oldRow.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }

        newRow.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        newDotView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.width.height.equalTo(36)
        }

        newInfoStack.snp.makeConstraints {
            $0.leading.equalTo(newDotView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        // Action Row
        actionRow.snp.makeConstraints {
            $0.top.equalTo(compareView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(48)
        }

        hexHashLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
        }
        hexValueLabel.snp.makeConstraints {
            $0.leading.equalTo(hexHashLabel.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
        }
        hexDotView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        // Tip Row
        tipRow.snp.makeConstraints {
            $0.top.equalTo(actionRow.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        tipIconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(16)
        }

        tipLabel.snp.makeConstraints {
            $0.leading.equalTo(tipIconView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(14)
            $0.top.bottom.equalToSuperview().inset(10)
        }

        // Apply
        applyButton.snp.makeConstraints {
            $0.top.equalTo(tipRow.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(52)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }

    private func configureContent() {
        // Old color
        oldDotView.backgroundColor = currentMission.color
        oldBottomLabel.text = "\(currentMission.name) · \(currentMission.hexColor)"

        // New color
        applyPendingColor()
    }

    private func applyPendingColor() {
        newDotView.backgroundColor = pendingColor
        newDotView.layer.borderWidth = 3
        newDotView.layer.borderColor = pendingColor.withAlphaComponent(0.3).cgColor

        let hexWithout = String(pendingHex.dropFirst())
        newBottomLabel.text = "\(pendingName) · \(pendingHex)"

        hexValueLabel.text = hexWithout
        hexDotView.backgroundColor = pendingColor
    }

    // MARK: - Bind
    private func bind() {
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismissSheet() })
            .disposed(by: disposeBag)

        randomButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let preset = ColorPickerSheetViewController.presets.randomElement()!
                self.pendingColor = preset.color
                self.pendingHex = preset.hex
                self.pendingName = preset.name
                self.applyPendingColor()
            })
            .disposed(by: disposeBag)

        hexDisplayButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let palette = ColorPalettePickerSheetViewController()
                palette.modalPresentationStyle = .overFullScreen
                palette.onColorPicked = { [weak self] color, hex in
                    self?.pendingColor = color
                    self?.pendingHex = hex
                    self?.pendingName = "직접 선택한 색상"
                    self?.applyPendingColor()
                }
                self.present(palette, animated: false)
            })
            .disposed(by: disposeBag)

        applyButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.onApply?(self.pendingColor, self.pendingHex, self.pendingName)
                self.dismissAll()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    @objc private func overlayTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: view)
        if !sheetView.frame.contains(loc) { dismissSheet() }
    }

    // MARK: - Dismiss
    private func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.sheetView.frame.height)
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    private func dismissAll() {
        let presenter = presentingViewController
        UIView.animate(withDuration: 0.25, animations: {
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.sheetView.frame.height)
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false) {
                if let picker = presenter as? ColorPickerSheetViewController {
                    picker.dismissSheet()
                } else {
                    presenter?.dismiss(animated: false)
                }
            }
        }
    }
}
