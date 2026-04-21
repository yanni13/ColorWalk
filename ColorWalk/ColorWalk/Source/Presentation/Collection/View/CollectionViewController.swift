import UIKit
import SnapKit
import LinkPresentation
import RxSwift
import RxCocoa
import Photos

final class CollectionViewController: BaseViewController {

    // MARK: - Constants

    private enum Constants {
        static let shareCardWidth: CGFloat = 390
        static let shareCardHeight: CGFloat = 506
    }

    // MARK: - Properties

    weak var coordinator: CollectionCoordinator?
    private let viewModel: CollectionViewModel
    private let viewWillAppearRelay = PublishRelay<Void>()
    private var currentSlots: [SlotDisplayInfo] = []
    private var currentMissionHex: String = ""
    private var currentShareDateText: String = ""
    private var currentMissionDateIdentifier: String = ""

    // MARK: - Gradient

    private let backgroundGradientLayer = CAGradientLayer()
    
    // MARK: - UI: Scroll

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView = UIView()

    // MARK: - UI: Cards

    private let missionHeaderCard: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 1.0
        return view
    }()

    private let archiveGridCard: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 1.0
        return view
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return stack
    }()

    // MARK: - UI: Mission Info (XfU13)

    private let missionInfoRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return stack
    }()

    private let colorDotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.backgroundColor = UIColor(hex: "#F7F8FA")
        return view
    }()

    private let infoTextStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()

    private let missionNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-SemiBold", size: 14)
        label.textColor = UIColor(hex: "#191F28")
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Medium", size: 12)
        label.textColor = UIColor(hex: "#B0B8C1")
        return label
    }()

    // MARK: - UI: Grid Card Content (hRzrP)

    private let gridCardStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return stack
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Bold", size: 18)
        label.textColor = UIColor(hex: "#191F28")
        return label
    }()

    private let dateNavRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    private let prevButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(hex: "#B0B8C1")
        return button
    }()

    private let nextButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(hex: "#B0B8C1")
        return button
    }()

    private let photoGridView = MissionPhotoGridView()

    // MARK: - UI: Empty State

    private let emptyStateStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private let emptyIconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .thin)
        let imageView = UIImageView(image: UIImage(systemName: "figure.walk.circle", withConfiguration: config))
        imageView.tintColor = UIColor(hex: "#B0B8C1")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.emptyTitle
        label.font = UIFont(name: "Pretendard-Bold", size: 28)
        label.textColor = UIColor(hex: "#191F28")
        label.textAlignment = .center
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.emptySubtitle
        label.font = UIFont(name: "Pretendard-Medium", size: 14)
        label.textColor = UIColor(hex: "#6B7684")
        label.textAlignment = .center
        return label
    }()

    // MARK: - UI: Action Icons

    private let shareIconButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
        button.tintColor = .gray
        return button
    }()

    private let editIconButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "pencil", withConfiguration: config), for: .normal)
        button.tintColor = .gray
        return button
    }()

    private let layoutButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "square.grid.2x2", withConfiguration: config), for: .normal)
        button.tintColor = .gray
        button.accessibilityLabel = L10n.accessibilityChangeLayout
        return button
    }()

    // MARK: - Dropdown State

    private var currentGridLayout: GridLayoutType {
        return GridLayoutStore.shared.selectedLayout.value
    }
    private weak var dropdownView: GridLayoutDropdownView?
    private weak var dropdownDismissOverlay: UIView?

    // MARK: - UI: State & Share

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.missionStatusInProgress
        label.font = UIFont(name: "Pretendard-Medium", size: 13)
        label.textColor = UIColor(hex: "#B0B8C1")
        label.textAlignment = .center
        return label
    }()

    private let shareHintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Medium", size: 13)
        label.textColor = UIColor(hex: "#6B7684")
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    init(viewModel: CollectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    // MARK: - Setup

    override func setupViews() {
        view.backgroundColor = UIColor(hex: "#F7F8FA")
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)
        
        // Share Hint
        contentStackView.addArrangedSubview(shareHintLabel)

        // Mission Header (XfU13)
        contentStackView.addArrangedSubview(missionHeaderCard)
        missionHeaderCard.addSubview(missionInfoRow)
        missionInfoRow.addArrangedSubview(colorDotView)
        missionInfoRow.addArrangedSubview(infoTextStack)
        infoTextStack.addArrangedSubview(missionNameLabel)
        infoTextStack.addArrangedSubview(metaLabel)
        
        // Archive Grid (hRzrP)
        contentStackView.addArrangedSubview(archiveGridCard)
        archiveGridCard.addSubview(gridCardStack)
        
        // Header Row (Buttons at edges, Date perfectly centered)
        let navContainer = UIView()
        navContainer.addSubview(prevButton)
        navContainer.addSubview(dateLabel)
        navContainer.addSubview(nextButton)
        
        prevButton.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        nextButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        navContainer.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        
        // Action Row (Bottom Right)
        let actionStack = UIStackView(arrangedSubviews: [shareIconButton, editIconButton, layoutButton])
        actionStack.axis = .horizontal
        actionStack.spacing = 16
        actionStack.alignment = .center
        
        let actionRow = UIStackView(arrangedSubviews: [UIView(), actionStack])
        actionRow.axis = .horizontal
        
        gridCardStack.addArrangedSubview(navContainer)
        gridCardStack.addArrangedSubview(photoGridView)
        gridCardStack.addArrangedSubview(actionRow)
        gridCardStack.addArrangedSubview(emptyStateStack)
        
        emptyStateStack.addArrangedSubview(emptyIconImageView)
        emptyStateStack.addArrangedSubview(emptyTitleLabel)
        emptyStateStack.addArrangedSubview(emptySubtitleLabel)
        
        contentStackView.addArrangedSubview(stateLabel)
        
        photoGridView.setLayout(currentGridLayout)
        configureInitialState()
    }

    private func configureInitialState() {
        shareHintLabel.isHidden = true
        missionHeaderCard.isHidden = true
        photoGridView.isHidden = true
        stateLabel.isHidden = true
        emptyStateStack.isHidden = true

        shareIconButton.isHidden = true
        editIconButton.isHidden = false
        editIconButton.isEnabled = true
        editIconButton.tintColor = .gray
        layoutButton.isHidden = true
    }

    // MARK: - Constraints

    override func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        missionInfoRow.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        colorDotView.snp.makeConstraints { make in
            make.width.height.equalTo(28)
        }
        
        gridCardStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        prevButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        nextButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        shareIconButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        editIconButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        layoutButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        photoGridView.snp.makeConstraints { make in
            make.height.equalTo(photoGridView.snp.width).multipliedBy(currentGridLayout.aspectRatioMultiplier)
        }
        emptyStateStack.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(200)
        }
    }

    // MARK: - Bind

    override func bind() {
        let output = viewModel.transform(input: makeInput())
        
        output.dateText
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)

        output.missionColorHex
            .drive(onNext: { [weak self] hex in
                guard let self else { return }
                self.currentMissionHex = hex
                self.colorDotView.backgroundColor = UIColor(hex: hex)
                self.missionNameLabel.text = L10n.collectionMissionColor
                self.applyGradient(for: UIColor(hex: hex))
            })
            .disposed(by: disposeBag)

        output.shareDateText
            .drive(onNext: { [weak self] text in
                self?.currentShareDateText = text
            })
            .disposed(by: disposeBag)

        output.missionState
            .drive(onNext: { [weak self] state in
                self?.applyState(state)
            })
            .disposed(by: disposeBag)

        output.canGoNext
            .drive(onNext: { [weak self] canGo in
                guard let self else { return }
                self.nextButton.isEnabled = canGo
                self.nextButton.alpha = canGo ? 1.0 : 0.3
            })
            .disposed(by: disposeBag)

        output.missionDateIdentifier
            .drive(onNext: { [weak self] identifier in
                self?.currentMissionDateIdentifier = identifier
            })
            .disposed(by: disposeBag)

        shareIconButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentShareSheet()
            })
            .disposed(by: disposeBag)

        editIconButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigateToEdit()
            })
            .disposed(by: disposeBag)

        layoutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.toggleLayoutDropdown()
            })
            .disposed(by: disposeBag)
    }

    private func makeInput() -> CollectionViewModel.Input {
        CollectionViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            prevDayTap: prevButton.rx.tap.asObservable(),
            nextDayTap: nextButton.rx.tap.asObservable()
        )
    }

    // MARK: - State

    private func applyState(_ state: MissionState) {
        switch state {
        case .noMission:
            shareHintLabel.isHidden = true
            missionHeaderCard.isHidden = true
            photoGridView.isHidden = true
            stateLabel.isHidden = true
            emptyStateStack.isHidden = false
            photoGridView.clearSlots()
            currentSlots = []

            shareIconButton.isHidden = true
            editIconButton.isHidden = true
            layoutButton.isHidden = true
            hideLayoutDropdown()

        case .inProgress(_, let slots):
            currentSlots = slots
            shareHintLabel.isHidden = false
            missionHeaderCard.isHidden = false
            photoGridView.isHidden = false
            emptyStateStack.isHidden = true
            photoGridView.configure(with: slots)

            shareIconButton.isHidden = false
            editIconButton.isHidden = false
            editIconButton.isEnabled = true
            editIconButton.tintColor = .gray
            layoutButton.isHidden = false

            updateMissionDisplay()

        case .completed(let slots):
            currentSlots = slots
            shareHintLabel.isHidden = false
            missionHeaderCard.isHidden = false
            photoGridView.isHidden = false
            emptyStateStack.isHidden = true
            photoGridView.configure(with: slots)

            shareIconButton.isHidden = false
            editIconButton.isHidden = false
            editIconButton.isEnabled = true
            editIconButton.tintColor = .gray
            layoutButton.isHidden = false

            updateMissionDisplay()
        }
    }

    // MARK: - Lifecycle

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
    }

    // MARK: - Action

    private func applyGradient(for color: UIColor) {
        let newColors: [CGColor] = [
            color.withAlphaComponent(0.33).cgColor,
            color.withAlphaComponent(0.22).cgColor,
            color.withAlphaComponent(0.10).cgColor,
            UIColor.clear.cgColor
        ]
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        backgroundGradientLayer.colors = newColors
        CATransaction.commit()
        backgroundGradientLayer.locations = [0, 0.4, 0.7, 1.0]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }

    private func toggleLayoutDropdown() {
        if dropdownView != nil {
            hideLayoutDropdown()
            return
        }

        let overlay = UIView()
        overlay.backgroundColor = .clear
        overlay.frame = view.bounds
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideLayoutDropdown)))
        view.addSubview(overlay)
        dropdownDismissOverlay = overlay

        let dropdown = GridLayoutDropdownView()
        dropdown.setSelectedLayout(currentGridLayout)
        dropdown.onSelect = { [weak self] layout in
            self?.applyGridLayout(layout)
            self?.hideLayoutDropdown()
        }
        dropdown.show(anchoredTo: layoutButton, in: view)
        dropdownView = dropdown
    }

    @objc private func hideLayoutDropdown() {
        dropdownView?.dismiss()
        dropdownDismissOverlay?.removeFromSuperview()
        dropdownView = nil
        dropdownDismissOverlay = nil
    }

    private func applyGridLayout(_ layout: GridLayoutType) {
        GridLayoutStore.shared.updateLayout(layout)
        photoGridView.setLayout(layout)
        photoGridView.snp.remakeConstraints { make in
            make.height.equalTo(photoGridView.snp.width).multipliedBy(layout.aspectRatioMultiplier)
        }
        updateMissionDisplay()
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateMissionDisplay() {
        guard !currentSlots.isEmpty else { return }

        let gridSlotCount = currentGridLayout.slotCount
        let capturedCount = currentSlots.filter { $0.isCaptured }.count
        let displayedCaptured = min(capturedCount, gridSlotCount)
        let isGridComplete = capturedCount >= gridSlotCount

        if isGridComplete {
            metaLabel.text = L10n.missionCompleteStatus(total: gridSlotCount)
        } else {
            metaLabel.text = L10n.missionIncompleteStatus(captured: displayedCaptured, total: gridSlotCount)
        }

        shareHintLabel.text = L10n.collectionShareHint(count: gridSlotCount)
        shareIconButton.isEnabled = isGridComplete
        shareIconButton.tintColor = isGridComplete ? .gray : .lightGray
        stateLabel.isHidden = isGridComplete
    }

    private func navigateToEdit() {
        guard !currentMissionDateIdentifier.isEmpty else { return }
        coordinator?.presentEdit(missionDateIdentifier: currentMissionDateIdentifier)
    }

    private func presentShareSheet() {
        guard !currentSlots.isEmpty else { return }
        AnalyticsManager.shared.logCollectionShared()

        let cardSize = CGSize(width: Constants.shareCardWidth, height: Constants.shareCardHeight)
        let container = UIView(frame: CGRect(origin: .zero, size: cardSize))

        let cardView = InstagramShareCardView()
        cardView.configure(slots: currentSlots, missionHex: currentMissionHex, dateText: currentShareDateText, layout: currentGridLayout)
        container.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        container.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: cardSize)
        let image = renderer.image { context in
            container.layer.render(in: context.cgContext)
        }

        let itemSource = GridShareItemSource(image: image, title: L10n.collectionShareTitle, date: currentShareDateText)

        var applicationActivities: [UIActivity] = []
        if let pngData = image.pngData() {
            applicationActivities.append(SaveAsPNGToPhotosActivity(imageData: pngData))
        }

        let activityVC = UIActivityViewController(
            activityItems: [itemSource],
            applicationActivities: applicationActivities
        )
        activityVC.excludedActivityTypes = [.saveToCameraRoll]

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareIconButton
        }

        activityVC.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            guard let self, completed else { return }
            self.showShareToast()
        }

        present(activityVC, animated: true)
    }

    private func showShareToast() {
        let toast = UIView()
        toast.backgroundColor = UIColor(hex: "#1A1A1A").withAlphaComponent(0.88)
        toast.layer.cornerRadius = 20
        view.addSubview(toast)

        let label = UILabel()
        label.text = L10n.collectionShareToast
        label.font = UIFont(name: "Pretendard-SemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        toast.addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20))
        }
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
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
}

// MARK: - Share Item Source

final class GridShareItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let title: String
    let date: String

    init(image: UIImage, title: String, date: String) {
        self.image = image
        self.title = title
        self.date = date
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
        metadata.originalURL = URL(string: "https://colorwalk.app") // Placeholder
        metadata.imageProvider = NSItemProvider(object: image)
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}

// MARK: - SaveAsPNGToPhotosActivity

final class SaveAsPNGToPhotosActivity: UIActivity {

    private enum Constants {
        static let title = "사진에 저장"
    }

    private let imageData: Data

    init(imageData: Data) {
        self.imageData = imageData
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
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.uniformTypeIdentifier = "public.png"
            request.addResource(with: .photo, data: data, options: options)
            request.creationDate = Date()
        }) { [weak self] success, _ in
            self?.activityDidFinish(success)
        }
    }
}
