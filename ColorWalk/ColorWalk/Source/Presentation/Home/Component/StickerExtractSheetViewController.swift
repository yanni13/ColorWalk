import UIKit
import SnapKit

final class StickerExtractSheetViewController: UIViewController {

    // MARK: - Properties

    private let stickerImage: UIImage
    private let colorName: String
    private let hexColor: String

    var onSave: (() -> Void)?
    var onCopy: (() -> Void)?
    var onShare: (() -> Void)?

    private enum Constants {
        static let sheetHeight: CGFloat = 300
        static let handleWidth: CGFloat = 36
        static let handleHeight: CGFloat = 4
        static let thumbSize: CGFloat = 56
        static let thumbCornerRadius: CGFloat = 12
        static let actionRowHeight: CGFloat = 52
        static let sheetCornerRadius: CGFloat = 24
    }

    // MARK: - UI

    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0)
        return v
    }()

    private let sheetView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = Constants.sheetCornerRadius
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let v = UIVisualEffectView(effect: blur)
        return v
    }()

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        v.layer.cornerRadius = Constants.handleHeight / 2
        return v
    }()

    private let thumbImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = Constants.thumbCornerRadius
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Pretendard-SemiBold", size: 15)
        l.textColor = .white
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "배경이 제거된 스티커로 저장됩니다"
        l.font = UIFont(name: "Pretendard-Regular", size: 12)
        l.textColor = UIColor.white.withAlphaComponent(0.5)
        return l
    }()

    private lazy var infoStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.axis = .vertical
        s.spacing = 4
        return s
    }()

    private let previewRow = UIView()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return v
    }()

    private let saveButton = StickerExtractSheetViewController.makeActionButton(
        systemName: "star.fill",
        title: "스티커 보관함에 저장",
        tintColor: UIColor(hex: "#FF7EB3")
    )

    private let copyButton = StickerExtractSheetViewController.makeActionButton(
        systemName: "doc.on.doc",
        title: "스티커 복사하기",
        tintColor: UIColor.white.withAlphaComponent(0.6)
    )

    private let shareButton = StickerExtractSheetViewController.makeActionButton(
        systemName: "square.and.arrow.up",
        title: "다른 앱으로 공유",
        tintColor: UIColor.white.withAlphaComponent(0.6)
    )

    // MARK: - Init

    init(stickerImage: UIImage, colorName: String, hexColor: String) {
        self.stickerImage = stickerImage
        self.colorName = colorName
        self.hexColor = hexColor
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .coverVertical
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureContent()
        bindActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        sheetView.transform = CGAffineTransform(translationX: 0, y: Constants.sheetHeight)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.sheetView.transform = .identity
            self.overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(overlayView)
        view.addSubview(sheetView)
        sheetView.addSubview(blurView)
        sheetView.addSubview(handleView)
        sheetView.addSubview(previewRow)
        previewRow.addSubview(thumbImageView)
        previewRow.addSubview(infoStack)
        sheetView.addSubview(divider)
        sheetView.addSubview(saveButton)
        sheetView.addSubview(copyButton)
        sheetView.addSubview(shareButton)

        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:)))
        overlayView.addGestureRecognizer(overlayTap)

        saveButton.accessibilityLabel = "스티커 보관함에 저장"
        copyButton.accessibilityLabel = "스티커 복사하기"
        shareButton.accessibilityLabel = "다른 앱으로 공유"
    }

    private func setupConstraints() {
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        sheetView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Constants.sheetHeight + view.safeAreaInsets.bottom)
        }

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        handleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(Constants.handleWidth)
            make.height.equalTo(Constants.handleHeight)
        }

        previewRow.snp.makeConstraints { make in
            make.top.equalTo(handleView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(Constants.thumbSize)
        }

        thumbImageView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(Constants.thumbSize)
        }

        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(thumbImageView.snp.trailing).offset(14)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(previewRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.actionRowHeight)
        }

        copyButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.actionRowHeight)
        }

        shareButton.snp.makeConstraints { make in
            make.top.equalTo(copyButton.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Constants.actionRowHeight)
        }
    }

    private func configureContent() {
        thumbImageView.image = stickerImage
        titleLabel.text = "\(colorName) 스티커"
    }

    // MARK: - Actions

    private func bindActions() {
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }

    @objc private func overlayTapped(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: view)
        if !sheetView.frame.contains(loc) {
            dismissSheet()
        }
    }

    @objc private func saveTapped() {
        dismissSheet { [weak self] in
            self?.onSave?()
        }
    }

    @objc private func copyTapped() {
        dismissSheet { [weak self] in
            self?.onCopy?()
        }
    }

    @objc private func shareTapped() {
        dismissSheet { [weak self] in
            self?.onShare?()
        }
    }

    // MARK: - Dismiss

    func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: Constants.sheetHeight)
            self.overlayView.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    // MARK: - Helper

    private static func makeActionButton(systemName: String, title: String, tintColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.imagePadding = 14
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        config.image = UIImage(systemName: systemName, withConfiguration: symbolConfig)
        config.baseForegroundColor = tintColor
        var title = AttributedString(title)
        title.font = UIFont(name: "Pretendard-Medium", size: 15) ?? .systemFont(ofSize: 15, weight: .medium)
        title.foregroundColor = tintColor
        config.attributedTitle = title
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        return button
    }
}
