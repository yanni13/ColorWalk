import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CollectionViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: CollectionViewModel
    private let viewWillAppearRelay = PublishRelay<Void>()

    // MARK: - UI: Scroll

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - UI: Card

    private let archiveCard: UIView = {
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
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return stack
    }()

    // MARK: - UI: Mission Info

    private let missionInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        return stack
    }()

    private let colorDotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.backgroundColor = UIColor.App.bgSecondary
        view.accessibilityLabel = "미션 색상"
        return view
    }()

    private let infoTextStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()

    private let colorHexLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-SemiBold", size: 14) ?? .boldSystemFont(ofSize: 14)
        label.textColor = UIColor.App.textPrimary
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Medium", size: 12) ?? .systemFont(ofSize: 12)
        label.textColor = UIColor.App.textTertiary
        return label
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.divider
        return view
    }()

    // MARK: - UI: Date Navigation

    private let dateNavRow = UIView()

    private let prevButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = UIColor.App.textPrimary
        button.accessibilityLabel = "이전 날짜"
        return button
    }()

    private let nextButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = UIColor.App.textPrimary
        button.accessibilityLabel = "다음 날짜"
        return button
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Pretendard-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        label.textColor = UIColor.App.textPrimary
        label.textAlignment = .center
        return label
    }()

    // MARK: - UI: Photo Grid

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
        let imageView = UIImageView(
            image: UIImage(systemName: "figure.walk.circle", withConfiguration: config)
        )
        imageView.tintColor = UIColor.App.textTertiary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = AppConstants.Text.noMissionTitle
        label.font = UIFont(name: "Pretendard-Bold", size: 28) ?? .boldSystemFont(ofSize: 28)
        label.textColor = UIColor.App.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = AppConstants.Text.noMissionSubtitle
        label.font = UIFont(name: "Pretendard-Medium", size: 14) ?? .systemFont(ofSize: 14)
        label.textColor = UIColor.App.textSecondary
        label.textAlignment = .center
        return label
    }()

    // MARK: - UI: State & Share

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.text = AppConstants.Text.inProgressMessage
        label.font = UIFont(name: "Pretendard-Medium", size: 13) ?? .systemFont(ofSize: 13)
        label.textColor = UIColor.App.textTertiary
        label.textAlignment = .center
        return label
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(AppConstants.Text.shareButtonTitle, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Pretendard-SemiBold", size: 16) ?? .boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor.App.progressStart
        button.layer.cornerRadius = 14
        button.accessibilityLabel = AppConstants.Text.shareButtonTitle
        return button
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
        view.backgroundColor = UIColor.App.bgSecondary
        addScrollHierarchy()
        addCardContent()
        configureInitialState()
    }

    private func addScrollHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(archiveCard)
        archiveCard.addSubview(contentStackView)
    }

    private func addCardContent() {
        missionInfoStack.addArrangedSubview(colorDotView)
        infoTextStack.addArrangedSubview(colorHexLabel)
        infoTextStack.addArrangedSubview(metaLabel)
        missionInfoStack.addArrangedSubview(infoTextStack)

        dateNavRow.addSubview(prevButton)
        dateNavRow.addSubview(dateLabel)
        dateNavRow.addSubview(nextButton)

        emptyStateStack.addArrangedSubview(emptyIconImageView)
        emptyStateStack.addArrangedSubview(emptyTitleLabel)
        emptyStateStack.addArrangedSubview(emptySubtitleLabel)

        contentStackView.addArrangedSubview(missionInfoStack)
        contentStackView.addArrangedSubview(separatorView)
        contentStackView.addArrangedSubview(dateNavRow)
        contentStackView.addArrangedSubview(photoGridView)
        contentStackView.addArrangedSubview(emptyStateStack)
        contentStackView.addArrangedSubview(stateLabel)
        contentStackView.addArrangedSubview(shareButton)

        contentStackView.setCustomSpacing(8, after: missionInfoStack)
    }

    private func configureInitialState() {
        missionInfoStack.isHidden = true
        separatorView.isHidden = true
        photoGridView.isHidden = true
        stateLabel.isHidden = true
        shareButton.isHidden = true
        emptyStateStack.isHidden = true
    }

    // MARK: - Constraints

    override func setupConstraints() {
        constrainScroll()
        constrainCard()
        constrainDateNav()
        constrainCardContent()
    }

    private func constrainScroll() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
    }

    private func constrainCard() {
        archiveCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func constrainDateNav() {
        prevButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(prevButton.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualTo(nextButton.snp.leading).offset(-4)
        }
        dateNavRow.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    private func constrainCardContent() {
        colorDotView.snp.makeConstraints { make in
            make.width.height.equalTo(28)
        }
        separatorView.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        photoGridView.snp.makeConstraints { make in
            make.height.equalTo(photoGridView.snp.width)
        }
        emptyStateStack.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(200)
        }
        shareButton.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
    }

    // MARK: - Bind

    override func bind() {
        let output = viewModel.transform(input: makeInput())
        bindDateText(output: output)
        bindMissionInfo(output: output)
        bindMissionState(output: output)
        bindNavigation(output: output)
        bindShareButton()
    }

    private func makeInput() -> CollectionViewModel.Input {
        CollectionViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            prevDayTap: prevButton.rx.tap.asObservable(),
            nextDayTap: nextButton.rx.tap.asObservable()
        )
    }

    private func bindDateText(output: CollectionViewModel.Output) {
        output.dateText
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
    }

    private func bindMissionInfo(output: CollectionViewModel.Output) {
        output.missionColorHex
            .drive(onNext: { [weak self] hex in
                guard let self else { return }
                self.colorDotView.backgroundColor = UIColor(hex: hex)
                self.colorHexLabel.text = hex
            })
            .disposed(by: disposeBag)

        output.missionMetaText
            .drive(metaLabel.rx.text)
            .disposed(by: disposeBag)
    }

    private func bindMissionState(output: CollectionViewModel.Output) {
        output.missionState
            .drive(onNext: { [weak self] state in
                self?.applyState(state)
            })
            .disposed(by: disposeBag)
    }

    private func bindNavigation(output: CollectionViewModel.Output) {
        output.canGoNext
            .drive(onNext: { [weak self] canGo in
                guard let self else { return }
                self.nextButton.isEnabled = canGo
                self.nextButton.alpha = canGo ? 1.0 : 0.3
            })
            .disposed(by: disposeBag)
    }

    private func bindShareButton() {
        shareButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentShareSheet()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - State

    private func applyState(_ state: MissionState) {
        switch state {
        case .noMission: showNoMission()
        case .inProgress(_, let slots): showInProgress(slots: slots)
        case .completed(let slots): showCompleted(slots: slots)
        }
    }

    private func showNoMission() {
        missionInfoStack.isHidden = true
        separatorView.isHidden = true
        photoGridView.isHidden = true
        stateLabel.isHidden = true
        shareButton.isHidden = true
        emptyStateStack.isHidden = false
        photoGridView.clearSlots()
    }

    private func showInProgress(slots: [SlotDisplayInfo]) {
        missionInfoStack.isHidden = false
        separatorView.isHidden = false
        photoGridView.isHidden = false
        stateLabel.isHidden = false
        shareButton.isHidden = true
        emptyStateStack.isHidden = true
        photoGridView.configure(with: slots)
    }

    private func showCompleted(slots: [SlotDisplayInfo]) {
        missionInfoStack.isHidden = false
        separatorView.isHidden = false
        photoGridView.isHidden = false
        stateLabel.isHidden = true
        shareButton.isHidden = false
        emptyStateStack.isHidden = true
        photoGridView.configure(with: slots)
    }

    // MARK: - Action

    private func presentShareSheet() {
        let renderer = UIGraphicsImageRenderer(bounds: archiveCard.bounds)
        let image = renderer.image { _ in
            archiveCard.drawHierarchy(in: archiveCard.bounds, afterScreenUpdates: true)
        }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
