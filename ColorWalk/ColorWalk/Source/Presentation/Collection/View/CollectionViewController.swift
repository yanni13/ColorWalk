import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CollectionViewController: BaseViewController {

    // MARK: - Constants

    private enum Constants {
        static let shareCardWidth: CGFloat = 390
        static let shareCardHeight: CGFloat = 506
    }

    // MARK: - Properties

    private let viewModel: CollectionViewModel
    private let viewWillAppearRelay = PublishRelay<Void>()
    private var currentSlots: [SlotDisplayInfo] = []
    private var currentMissionHex: String = ""
    private var currentShareDateText: String = ""
    
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
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()

    private let prevButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(hex: "#B0B8C1")
        return button
    }()

    private let nextButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
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
        label.text = "텅~"
        label.font = UIFont(name: "Pretendard-Bold", size: 28)
        label.textColor = UIColor(hex: "#191F28")
        label.textAlignment = .center
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "이 날은 산책을 하지 않았어요."
        label.font = UIFont(name: "Pretendard-Medium", size: 14)
        label.textColor = UIColor(hex: "#6B7684")
        label.textAlignment = .center
        return label
    }()

    // MARK: - UI: State & Share

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.text = "아쉬워요 😢 미션을 완성하지 못했어요."
        label.font = UIFont(name: "Pretendard-Medium", size: 13)
        label.textColor = UIColor(hex: "#B0B8C1")
        label.textAlignment = .center
        return label
    }()

    private let shareHintLabel: UILabel = {
        let label = UILabel()
        label.text = "9개의 미션을 수행하면 그리드를 공유할 수 있어요!"
        label.font = UIFont(name: "Pretendard-Medium", size: 13)
        label.textColor = UIColor(hex: "#6B7684")
        label.textAlignment = .center
        return label
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("공유하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Pretendard-SemiBold", size: 16)
        button.backgroundColor = UIColor(hex: "#34D399")
        button.layer.cornerRadius = 14
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
        view.backgroundColor = UIColor(hex: "#F7F8FA")
        
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
        gridCardStack.addArrangedSubview(dateNavRow)
        dateNavRow.addArrangedSubview(prevButton)
        dateNavRow.addArrangedSubview(dateLabel)
        dateNavRow.addArrangedSubview(nextButton)
        gridCardStack.addArrangedSubview(photoGridView)
        gridCardStack.addArrangedSubview(emptyStateStack)
        
        emptyStateStack.addArrangedSubview(emptyIconImageView)
        emptyStateStack.addArrangedSubview(emptyTitleLabel)
        emptyStateStack.addArrangedSubview(emptySubtitleLabel)
        
        contentStackView.addArrangedSubview(stateLabel)
        contentStackView.addArrangedSubview(shareButton)
        
        configureInitialState()
    }

    private func configureInitialState() {
        shareHintLabel.isHidden = true
        missionHeaderCard.isHidden = true
        photoGridView.isHidden = true
        stateLabel.isHidden = true
        shareButton.isHidden = true
        emptyStateStack.isHidden = true
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
        dateNavRow.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        prevButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        nextButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        photoGridView.snp.makeConstraints { make in
            make.height.equalTo(photoGridView.snp.width).multipliedBy(1.1)
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
        
        output.dateText
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)

        output.missionColorHex
            .drive(onNext: { [weak self] hex in
                guard let self else { return }
                self.currentMissionHex = hex
                self.colorDotView.backgroundColor = UIColor(hex: hex)
                self.missionNameLabel.text = "오늘의 미션 색상"
            })
            .disposed(by: disposeBag)

        output.shareDateText
            .drive(onNext: { [weak self] text in
                self?.currentShareDateText = text
            })
            .disposed(by: disposeBag)

        output.missionMetaText
            .drive(metaLabel.rx.text)
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

        shareButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentShareSheet()
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
            shareButton.isHidden = true
            emptyStateStack.isHidden = false
            photoGridView.clearSlots()

        case .inProgress(_, let slots):
            shareHintLabel.isHidden = false
            missionHeaderCard.isHidden = false
            photoGridView.isHidden = false
            stateLabel.isHidden = false
            shareButton.isHidden = false
            shareButton.isEnabled = false
            shareButton.alpha = 0.4
            emptyStateStack.isHidden = true
            photoGridView.configure(with: slots)

        case .completed(let slots):
            currentSlots = slots
            shareHintLabel.isHidden = false
            missionHeaderCard.isHidden = false
            photoGridView.isHidden = false
            stateLabel.isHidden = true
            shareButton.isHidden = false
            shareButton.isEnabled = true
            shareButton.alpha = 1.0
            emptyStateStack.isHidden = true
            photoGridView.configure(with: slots)
        }
    }

    // MARK: - Action

    private func presentShareSheet() {
        guard !currentSlots.isEmpty else { return }

        let cardSize = CGSize(width: Constants.shareCardWidth, height: Constants.shareCardHeight)
        let container = UIView(frame: CGRect(origin: .zero, size: cardSize))

        let cardView = InstagramShareCardView()
        cardView.configure(slots: currentSlots, missionHex: currentMissionHex, dateText: currentShareDateText)
        container.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        container.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: cardSize)
        let image = renderer.image { context in
            container.layer.render(in: context.cgContext)
        }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }
}
